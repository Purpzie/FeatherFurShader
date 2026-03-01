using UnityEditor;
using UnityEngine;

public class FeathersAndFurBindPoseBaker : EditorWindow
{
    //Enums ----------------------------------------------------------------------------------------

    private enum BindPoseUVChannel
    {
        UV2 = 1,
        UV3 = 2,
        UV4 = 3,
        UV5 = 4,
        UV6 = 5,
        UV7 = 6,
        UV8 = 7
    };

    //Variables ------------------------------------------------------------------------------------

    //options
    private Renderer mTargetRenderer = null;
    private Material mTargetMaterial = null;
    private BindPoseUVChannel mUvChannel = BindPoseUVChannel.UV6;

    //save window
    private string mOldAssetSavePath = ""; //the location of the previous mesh
    private string mLastUsedSavePath = ""; //the last path saved to this session

    //the mesh we are generating
    private Mesh mOutputMesh = null;

    //Unity Functions ----------------------------------------------------------------------------

    //render the tool UI
    private void OnGUI()
    {
        //display current target
        EditorGUILayout.ObjectField("Target Material", mTargetMaterial, typeof(Material), false);
        EditorGUILayout.ObjectField("Target Skinned Mesh Renderer", mTargetRenderer, typeof(Renderer), true);

        //check that we have a valid target renderer with a valid mesh and display the appropriate error if we don't
        bool hasValidMesh = false;
        if (mTargetRenderer == null)
        {
            EditorGUILayout.HelpBox("Target renderer not properly set! Open this tool from the material editor window on a renderer in the scene!", MessageType.Error);
        }
        else
        {
            Mesh targetMesh = FeathersAndFurToolUtilities.GetMeshFromRenderer(mTargetRenderer);

            if (targetMesh == null)
            {
                EditorGUILayout.HelpBox("Skinned Mesh Renderer does not have a mesh set! ", MessageType.Error);
            }
            else if (!targetMesh.isReadable)
            {
                EditorGUILayout.HelpBox("Mesh is not readable! Check the Read/Write checkbox on the mesh asset!", MessageType.Error);
            }
            else
            {
                hasValidMesh = true;
            }
        }

        EditorGUILayout.Space();

        mUvChannel = (BindPoseUVChannel)EditorGUILayout.EnumPopup("Bind Pose UV Channel", mUvChannel);

        //if we have a target material with the bind pose uv channel parameter
        if (mTargetMaterial != null && mTargetMaterial.HasInt("_BindPoseUvChannel"))
        {
            int uvChannel = (int)mUvChannel;

            //if the bind pose uv channel parameter doesn't match the one we have set in this tool
            if (mTargetMaterial.GetInt("_BindPoseUvChannel") != uvChannel)
            {
                EditorGUILayout.HelpBox("The UV channel does not match the one on the material!", MessageType.Warning);

                //add a button to update the bind pose channel on the material
                if (FeathersAndFurToolUtilities.IndentedButton("Update Material's Bind Pose UV Channel"))
                {
                    Undo.RecordObject(mTargetMaterial, "Set Material Bind Pose UV Channel");

                    mTargetMaterial.SetInt("_BindPoseUvChannel", uvChannel);

                    //disable the default unused keyword this is set when there is no bind pose
                    mTargetMaterial.DisableKeyword("_BINDPOSEUVCHANNEL_NONE");

                    //need to set all the bind pose uv channel keywords appropriately to recompile the material to actually use the specified uv channel 
                    for (int index = 1; index < 8; index++)
                    {
                        string keyword = "_BINDPOSEUVCHANNEL_UV" + (index + 1);

                        if (index == uvChannel)
                        {
                            mTargetMaterial.EnableKeyword(keyword);
                        }
                        else
                        {
                            mTargetMaterial.DisableKeyword(keyword);
                        }
                    }

                    Undo.FlushUndoRecordObjects();
                }
            }
        }

        EditorGUILayout.Space();

        //show a button to bake the mesh if it is valid
        if (hasValidMesh)
        {
            if (FeathersAndFurToolUtilities.IndentedButton("Generate Mesh With Baked Bind Pose"))
            {
                BakeMesh();
            }
        }

        EditorGUILayout.Space();

        //if a baked mesh has been generated
        if (mOutputMesh != null)
        {
            //display a preview of the mesh
            EditorGUILayout.ObjectField("Preview:", mOutputMesh, typeof(Mesh), false);

            //add a button to save the mesh as an asset
            if (FeathersAndFurToolUtilities.IndentedButton("Save Mesh"))
            {
                SaveMesh();
            }

            //add a button to apply the mesh to the renderer automatically
            if(mTargetRenderer is SkinnedMeshRenderer)
            {
                if (FeathersAndFurToolUtilities.IndentedButton("Apply Mesh To Renderer"))
                {
                    //record an undo for the renderer
                    Undo.RecordObject(mTargetRenderer, "Set Mesh");

                    (mTargetRenderer as SkinnedMeshRenderer).sharedMesh = mOutputMesh;

                    Undo.FlushUndoRecordObjects();

                    //update the unsaved changes message to specify that the applied mesh will disappear if unsaved
                    this.saveChangesMessage = "The baked mesh was applied to the renderer but was not saved!\n"
                                            + "The mesh will disappear when this tool is closed!";
                }
            }
            else if (mTargetRenderer is MeshRenderer)
            {
                MeshFilter filter = mTargetRenderer.GetComponent<MeshFilter>();
                if (filter)
                {
                    if (FeathersAndFurToolUtilities.IndentedButton("Apply Mesh To Renderer"))
                    {
                        //record an undo for the renderer
                        Undo.RecordObject(filter, "Set Mesh");

                        filter.sharedMesh = mOutputMesh;

                        Undo.FlushUndoRecordObjects();

                        //update the unsaved changes message to specify that the applied mesh will disappear if unsaved
                        this.saveChangesMessage = "The baked mesh was applied to the renderer but was not saved!\n"
                                                + "The mesh will disappear when this tool is closed!";
                    }
                }
            }
        }
    }

    //open the save window when Unity tries to save changes
    public override void SaveChanges()
    {
        SaveMesh();
    }

    //clean up the mesh
    private void OnDestroy()
    {
        //only destroy the mesh if it exists but was not saved as an asset
        if (mOutputMesh != null && !AssetDatabase.Contains(mOutputMesh))
        {
            DestroyImmediate(mOutputMesh);
        }
    }

    //Public Functions ----------------------------------------------------------------------------

    //called when the window is created to set the target material and renderer
    public void SetTarget(Material newTargetMaterial, Renderer newTargetRenderer)
    {
        mTargetMaterial = newTargetMaterial;
        mTargetRenderer = newTargetRenderer;
    }

    //Helper Functions ----------------------------------------------------------------------------

    //create the mesh with baked bind pose
    private bool BakeMesh()
    {
        if(mTargetRenderer == null)
        {
            return false;
        }

        Mesh targetMesh = FeathersAndFurToolUtilities.GetMeshFromRenderer(mTargetRenderer);
        if (targetMesh == null)
        {
            return false; 
        }

        //copy all of the baked vertex data and scale into an array
        Vector4[] bindPose = new Vector4[targetMesh.vertexCount];

        if (mTargetRenderer is SkinnedMeshRenderer)
        {
            //if this is a skinned mesh, bake the bind pose and blend shapes into a static mesh
            Mesh bakedPoseMesh = new Mesh();
            (mTargetRenderer as SkinnedMeshRenderer).BakeMesh(bakedPoseMesh);

            for (int index = 0; index < targetMesh.vertexCount; index++)
            {
                bindPose[index] = bakedPoseMesh.vertices[index];
                bindPose[index].w = bakedPoseMesh.normals[index].magnitude;
            }
        }
        else if (mTargetRenderer is MeshRenderer)
        {
            //if this is a static mesh, bake the bind pose after world space transformation
            for (int index = 0; index < targetMesh.vertexCount; index++)
            {
                bindPose[index] = mTargetRenderer.transform.TransformPoint(targetMesh.vertices[index]);
                bindPose[index].w = mTargetRenderer.transform.TransformVector(targetMesh.normals[index]).magnitude;
            }
        }
        else
        {
            return false;
        }

        //make a deep copy of the mesh
        Mesh oldOutputMesh = mOutputMesh;
        mOutputMesh = Instantiate(targetMesh);
        mOutputMesh.name = targetMesh.name + "_WithBakedBindPose";

        //copy the baked data into the specified uv channel
        mOutputMesh.SetUVs((int)mUvChannel, bindPose);

        //destroy the previous mesh if it was not saved as an asset
        //delay destroying it until after the new one is created in case it was being used on the target renderer
        if (oldOutputMesh != null && !AssetDatabase.Contains(oldOutputMesh))
        {
            DestroyImmediate(oldOutputMesh);
        }

        //update the filepath now incase we replace the mesh before saving
        TryUpdateFilepathToMeshLocation();

        //update the save state
        this.hasUnsavedChanges = true;
        this.saveChangesMessage = "Mesh is unsaved!";

        return true;
    }

    //stores the filepath of the mesh being rendered by the target renderer 
    private void TryUpdateFilepathToMeshLocation()
    {
        //check if the mesh exists and is a saved asset
        if (mTargetRenderer != null)
        {
            Mesh targetMesh = FeathersAndFurToolUtilities.GetMeshFromRenderer(mTargetRenderer);

            if (targetMesh != null && AssetDatabase.Contains(targetMesh))
            {
                //get the asset's folder's path
                string assetPath = AssetDatabase.GetAssetPath(targetMesh);
                mOldAssetSavePath = assetPath.Substring(0, assetPath.LastIndexOf('/') + 1);
            }
        }
    }

    //open a window to save the mesh as an asset
    private bool SaveMesh()
    {
        if (mOutputMesh != null)
        {
            //update the filepath to the current mesh location if it is already saved somewhere
            TryUpdateFilepathToMeshLocation();

            //if we have not saved yet this session try to use the save path of the previous mesh
            string bestSavePath = mLastUsedSavePath.Length > 0 ? mLastUsedSavePath : mOldAssetSavePath;
            string filepath = EditorUtility.SaveFilePanel("Save Mesh", bestSavePath, mOutputMesh.name + ".mesh", "mesh");

            int dataPathIndex = filepath.IndexOf(Application.dataPath);
            if (dataPathIndex >= 0)
            {
                //create the mesh asset
                filepath = "Assets" + filepath.Remove(0, dataPathIndex + Application.dataPath.Length);
                AssetDatabase.CreateAsset(mOutputMesh, filepath);

                //store the path the asset was saved in
                mLastUsedSavePath = filepath.Substring(0, filepath.LastIndexOf('/') + 1);

                //clear the unsaved changes
                this.hasUnsavedChanges = false;

                return true;
            }
        }

        return false;
    }
}