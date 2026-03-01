using UnityEditor;
using UnityEngine;

public class FeathersAndFurOptimizationTextureBaker : EditorWindow
{
    //Constants ------------------------------------------------------------------------------------

    private static float cLowPrecisionEpsilon = 0.004f; //slightly greater than the maximum error of a 16-bit float in the 0-1 range

    //Enums ----------------------------------------------------------------------------------------

    private enum DownsamplingSize
    {
        One = 1,
        Two = 2,
        Four = 4,
        Eight = 8,
        Sixteen = 16
    }

    //Variables ------------------------------------------------------------------------------------

    //the texture we are generating
    private Texture2D mOutputOptimizationTexture = null;

    //options
    private Material mTargetMaterial = null;
    private DownsamplingSize mDownsampleSize = DownsamplingSize.Eight;
    private bool mApplyGammaCorrection = false;

    //save window
    private string mOldAssetSavePath = ""; //the location of the previous texture
    private string mLastUsedSavePath = ""; //the last path saved to this session

    //Unity Functions ------------------------------------------------------------------------------

    //render the tool UI
    private void OnGUI()
    {
        //display current target
        EditorGUILayout.ObjectField("Target Material", mTargetMaterial, typeof(Material), false);

        EditorGUILayout.Space();

        //present options for texture generation
        mDownsampleSize = (DownsamplingSize)EditorGUILayout.EnumPopup("Downsample Size", mDownsampleSize);
        mApplyGammaCorrection = EditorGUILayout.Toggle("Apply Gamma Correction", mApplyGammaCorrection);

        //do various error checking for bad inputs before presenting the option to actually generate the texture
        if (mTargetMaterial == null)
        {
            EditorGUILayout.HelpBox("Target material not properly set! Open this tool from the material editor window!", MessageType.Info);
        }
        else
        {
            Texture2D parametersTexture = null;

            if (mTargetMaterial.HasTexture("_CoatParametersTexture"))
            {
                parametersTexture = mTargetMaterial.GetTexture("_CoatParametersTexture") as Texture2D;
            }

            if(parametersTexture == null)
            {
                EditorGUILayout.HelpBox("Material does not have a Card Parameters texture! ", MessageType.Error);
            }
            else if(!parametersTexture.isReadable)
            {
                EditorGUILayout.HelpBox("Material's coat parameters texture does not have Read/Write Enabled! Check the box in the texture's settings!", MessageType.Error);
            }
            else
            {
                //don't display the button to generate the optimization texture unless the parameters texture's dimensions are valid
                if (parametersTexture.width == parametersTexture.height
                    && parametersTexture.width > 8
                    && parametersTexture.height > 8
                    && IsPowerOfTwo(parametersTexture.width)
                    && IsPowerOfTwo(parametersTexture.height))
                {
                    EditorGUILayout.Space();

                    //only display this button if the target material is valid and has a texture of valid dimensions 
                    if (FeathersAndFurToolUtilities.IndentedButton("Generate Optimization Texture"))
                    {
                        GenerateOptimizationTexture(parametersTexture);
                    }
                }
                else
                {
                    EditorGUILayout.HelpBox("Material's coat parameters texture must be a square with power of 2 size and be at least 8x8!", MessageType.Error);
                }
            }
        }

        EditorGUILayout.Space();

        //if an optimization texture has been generated
        if (mOutputOptimizationTexture != null)
        {
            EditorGUILayout.LabelField("Preview", EditorStyles.boldLabel);
            FeathersAndFurToolUtilities.TexturePreview(mOutputOptimizationTexture);

            EditorGUILayout.Space();

            //add a button to save the texture as an asset
            if (FeathersAndFurToolUtilities.IndentedButton("Save Texture"))
            {
                SaveOptimizationTexture();
            }

            //add a button to apply the texture to the material automatically
            if(mTargetMaterial != null && mTargetMaterial.HasTexture("_CoatOptimizationTexture"))
            {
                if (FeathersAndFurToolUtilities.IndentedButton("Apply Texture To Material"))
                {
                    Undo.RecordObject(mTargetMaterial, "Set Optimization Texture on Material");

                    mTargetMaterial.SetTexture("_CoatOptimizationTexture", mOutputOptimizationTexture);

                    Undo.FlushUndoRecordObjects();

                    //update the unsaved changes message to specify that the applied texture will disappear if unsaved
                    this.saveChangesMessage = "Optimization texture was applied to the material but was not saved! \n"
                                            + "The texture will disappear next time play mode is entered or when the project is closed!";
                }
            }
        }
    }

    //open the save window when Unity tries to save changes
    public override void SaveChanges()
    {
        SaveOptimizationTexture();
    }

    //clean up the optimization texture
    private void OnDestroy()
    {
        //only destroy the texture if it exists but was not saved as an asset
        if (mOutputOptimizationTexture != null && !AssetDatabase.Contains(mOutputOptimizationTexture))
        {
            DestroyImmediate(mOutputOptimizationTexture);
        }
    }

    //Public Functions ----------------------------------------------------------------------------

    //called when the window is created to set the target
    public void SetTarget(Material newTargetMaterial)
    {
        mTargetMaterial = newTargetMaterial;
    }

    //Helper Functions ----------------------------------------------------------------------------

    //create the optimization texture from the coat parameters texture on the material
    private bool GenerateOptimizationTexture(Texture2D sourceParametersTexture)
    {
        //make sure the parameters texture exists
        if(sourceParametersTexture == null)
        {
            return false;
        }

        int downsampleSize = (int)mDownsampleSize;
        int downsampledWidth = Mathf.Max(8, sourceParametersTexture.width / downsampleSize);

        //the optimization texture is clamped to 8x8 at minimum, so get the actual amount of downsampling
        downsampleSize = sourceParametersTexture.width / downsampledWidth;

        //source texture and optimization texture must be square powers of 2
        //the optimization texture can't be bigger than the source parameters texture
        //and the downsampling must be an even fraction of the source texture
        if (!IsPowerOfTwo(sourceParametersTexture.width)
            || !IsPowerOfTwo(downsampledWidth)
            || (sourceParametersTexture.width != sourceParametersTexture.height)
            || (downsampleSize < 1)
            || (downsampledWidth * downsampleSize != sourceParametersTexture.width))
        {
            return false;
        }

        //release the old optimization texture's resources if it exists and isn't saved as an asset
        if(mOutputOptimizationTexture != null && !AssetDatabase.Contains(mOutputOptimizationTexture))
        {
            DestroyImmediate(mOutputOptimizationTexture);
        }

        //create a new optimization texture with mipmaps and a linear color space
        mOutputOptimizationTexture = new Texture2D(downsampledWidth, downsampledWidth, TextureFormat.RGHalf, true, true);
        mOutputOptimizationTexture.name = sourceParametersTexture.name + "_OptimizationTexture";

        //downsample the source texture

        Color[] sourcePixels = sourceParametersTexture.GetPixels(0);
        Color[] destinationPixels = new Color[downsampledWidth * downsampledWidth];

        //for every pixel in mip 0 of the optimization texture
        for (int destinationPixelX = 0; destinationPixelX < downsampledWidth; destinationPixelX++)
        {
            for(int destinationPixelY = 0; destinationPixelY < downsampledWidth; destinationPixelY++)
            {
                float minValue = 1.0f;
                float maxValue = 0.0f;

                //get the range of source pixels that will be downsampled into mip 0 of the optimization texture
                int downsampleBlockStartX = destinationPixelX * downsampleSize;
                int downsampleBlockEndX = downsampleBlockStartX + downsampleSize;
                int downsampleBlockStartY = destinationPixelY * downsampleSize;
                int downsampleBlockEndY = downsampleBlockStartY + downsampleSize;

                //downsample in the NxN neighborhood, add an extra pixel on each side to account for bilinear filtering
                for (int sourcePixelX = downsampleBlockStartX - 1; sourcePixelX < downsampleBlockEndX + 1; sourcePixelX++)
                {
                    for(int sourcePixelY = downsampleBlockStartY - 1; sourcePixelY < downsampleBlockEndY + 1; sourcePixelY++)
                    {
                        //clamp the source pixel coordinates to the edges of the texture and flatten the index
                        int sourcePixelIndex = Mathf.Clamp(sourcePixelX, 0, sourceParametersTexture.width - 1)
                                             + (Mathf.Clamp(sourcePixelY, 0, sourceParametersTexture.height - 1) * sourceParametersTexture.width);


                        Color sourceColor = sourcePixels[sourcePixelIndex];
                        if (mApplyGammaCorrection)
                        {
                            sourceColor = sourceColor.linear;
                        }

                        //check if cards on this pixel would be visible in the first place
                        //if not, don't count these towards the min and max for this optimization texture pixel
                        if(sourceColor.a > Mathf.Epsilon)
                        {
                            minValue = Mathf.Min(minValue, sourceColor.r);
                            maxValue = Mathf.Max(maxValue, sourceColor.r);
                        }
                    }
                }

                //bias by an epsilon to avoid a rounding error when we save these values as 16-bit floats in the final texture
                minValue = Mathf.Clamp01(minValue - cLowPrecisionEpsilon);
                maxValue = Mathf.Clamp01(maxValue + cLowPrecisionEpsilon);

                int pixelIndex = destinationPixelX + (destinationPixelY * downsampledWidth);
                destinationPixels[pixelIndex] = new Color(maxValue, minValue, 0.0f, 0.0f);
            }
        }

        //actually put the pixels into mip 0 of the optimization texture
        mOutputOptimizationTexture.SetPixels(destinationPixels, 0);

        //fill out mipmap levels of the optimization texture
        for (int mipLevel = 1; mipLevel < mOutputOptimizationTexture.mipmapCount; mipLevel++)
        {
            int mipWidth = downsampledWidth >> mipLevel;

            //the last mip's pixels become the new source, and we generate a new array for the current mip
            sourcePixels = destinationPixels;
            destinationPixels = new Color[mipWidth * mipWidth];

            //for every pixel in the current mip
            for (int destinationPixelX = 0; destinationPixelX < mipWidth; destinationPixelX++)
            {
                for (int destinationPixelY = 0; destinationPixelY < mipWidth; destinationPixelY++)
                {
                    float minValue = 1.0f;
                    float maxValue = 0.0f;

                    //downsample the 2x2 pixels from the lower mip
                    for (int sourcePixelX = destinationPixelX * 2; sourcePixelX <= (destinationPixelX * 2) + 1; sourcePixelX++)
                    {
                        for (int sourcePixelY = destinationPixelY * 2; sourcePixelY <= (destinationPixelY * 2) + 1; sourcePixelY++)
                        {
                            int sourcePixelIndex = sourcePixelX + (sourcePixelY * mipWidth * 2);
                            Color sourceColor = sourcePixels[sourcePixelIndex];

                            minValue = Mathf.Min(minValue, sourceColor.g);
                            maxValue = Mathf.Max(maxValue, sourceColor.r);
                        }
                    }

                    int pixelIndex = destinationPixelX + (destinationPixelY * mipWidth);
                    destinationPixels[pixelIndex] = new Color(maxValue, minValue, 0.0f, 0.0f);
                }
            }

            //actually put the pixels into the current mip of the texture
            mOutputOptimizationTexture.SetPixels(destinationPixels, mipLevel);
        }

        //don't auto generate mipmaps while applying the changes to the texture
        mOutputOptimizationTexture.Apply(false);

        //update the filepath now in case we replace the texture before saving
        TryUpdateFilepathToTextureLocation("_CoatOptimizationTexture");

        //if no save path was found try using the parameters texture's path instead
        if (mOldAssetSavePath.Length == 0)
        {
            TryUpdateFilepathToTextureLocation("_CoatParametersTexture");
        }

        //update the save state
        this.hasUnsavedChanges = true;
        this.saveChangesMessage = "Optimization texture is unsaved!";

        return true;
    }

    //stores the filepath of a texture on the target material 
    private void TryUpdateFilepathToTextureLocation(string textureName)
    {
        if (mTargetMaterial != null && mTargetMaterial.HasTexture(textureName))
        {
            Texture oldTexture = mTargetMaterial.GetTexture(textureName);

            //check if the texture exists and is a saved asset
            if (oldTexture != null && AssetDatabase.Contains(oldTexture))
            {
                //get the asset's folder's path
                string assetPath = AssetDatabase.GetAssetPath(oldTexture);
                mOldAssetSavePath = assetPath.Substring(0, assetPath.LastIndexOf('/') + 1);
            }
        }
    }

    //open a window to save the texture as an asset
    private bool SaveOptimizationTexture()
    {
        if (mOutputOptimizationTexture != null)
        {
            //update the filepath to the current optimization texture if it is already saved somewhere
            TryUpdateFilepathToTextureLocation("_CoatOptimizationTexture");

            //if we have not saved yet this session try to use the save path of the corresponding previous texture
            string bestSavePath = mLastUsedSavePath.Length > 0 ? mLastUsedSavePath : mOldAssetSavePath;
            string filepath = EditorUtility.SaveFilePanel("Save Optimization Texture", bestSavePath, mOutputOptimizationTexture.name + ".asset", "asset");

            int dataPathIndex = filepath.IndexOf(Application.dataPath);
            if (dataPathIndex >= 0)
            {
                //convert the filepath to a unity asset path
                filepath = "Assets" + filepath.Remove(0, dataPathIndex + Application.dataPath.Length);

                //check if an asset already exists at this path
                Texture2D textureAsset = AssetDatabase.LoadAssetAtPath<Texture2D>(filepath);

                //if the asset already exists, modify it rather than creating a new one
                if (textureAsset != null)
                {
                    //change the texture name to match the file we are saving it to
                    mOutputOptimizationTexture.name = textureAsset.name;

                    //copy all the texture data to the asset on disk
                    EditorUtility.CopySerialized(mOutputOptimizationTexture, textureAsset);

                    //if we had set the target material's texture to be the new optimization texture made by this tool
                    if (mTargetMaterial != null
                        && mTargetMaterial.HasTexture("_CoatOptimizationTexture")
                        && mTargetMaterial.GetTexture("_CoatOptimizationTexture") == mOutputOptimizationTexture)
                    {
                        Undo.RecordObject(mTargetMaterial, "Set Optimization Texture on Material");

                        //switch the texture on the material to the asset we just saved the texture data to
                        mTargetMaterial.SetTexture("_CoatOptimizationTexture", textureAsset);

                        Undo.FlushUndoRecordObjects();
                    }

                    //set the optimization texture we are working with to be the asset on disk we just copied the data to
                    //that way we aren't working with a separate texture inside this tool
                    DestroyImmediate(mOutputOptimizationTexture);
                    mOutputOptimizationTexture = textureAsset;
                }
                else
                {
                    AssetDatabase.CreateAsset(mOutputOptimizationTexture, filepath);
                }

                //store the path the asset was saved in
                mLastUsedSavePath = filepath.Substring(0, filepath.LastIndexOf('/') + 1);

                //clear the unsaved changes
                this.hasUnsavedChanges = false;

                return true;
            }
        }

        return false;
    }

    //checks if an integer is an exact power of 2
    private bool IsPowerOfTwo(int value)
    {
        return (value & (value - 1)) == 0;
    }
}