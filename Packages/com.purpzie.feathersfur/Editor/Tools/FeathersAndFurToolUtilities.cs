using UnityEditor;
using UnityEngine;

//shared helper functions for the feathers and fur tools and editors
public static class FeathersAndFurToolUtilities
{
    //Shared Tool Helpers --------------------------------------------------------------------------

    //get the mesh a skinned or static mesh renderer is currently using or return null for other renderer types
    public static Mesh GetMeshFromRenderer(Renderer renderer)
    {
        if (renderer is SkinnedMeshRenderer)
        {
            return (renderer as SkinnedMeshRenderer).sharedMesh;
        }
        else if (renderer is MeshRenderer)
        {
            MeshFilter filter = renderer.GetComponent<MeshFilter>();
            if (filter)
            {
                return filter.sharedMesh;
            }
        }

        return null;
    }

    //UI Helpers -----------------------------------------------------------------------------------

    //color used add a slightly dark tinted background for certain GUI elements
    public static readonly Color sBackgroundColor = new Color(0.0f, 0.0f, 0.0f, 0.075f);

    //the shader GUI indents content inside a foldout more than the editor GUI, so expose this value to 
    //allow for the foldout background to be adjusted to start the same horizontal position in both cases
    public static float sFoldoutIndentBackgroundCorrection = 5.0f;

    //adds a button which is indented to the current indent level and returns if it was clicked
    public static bool IndentedButton(string buttonText)
    {
        return GUI.Button(EditorGUI.IndentedRect(EditorGUILayout.GetControlRect()), buttonText);
    }

    //shows a preview image of a texture, which optionally can open the texture in the inspector when clicked
    public static void TexturePreview(Texture texture, bool clickable = true, float lineHeight = 8.0f)
    {
        //get an indented region to render the texture in with the specified height
        Rect rect = EditorGUILayout.GetControlRect(false, EditorGUIUtility.singleLineHeight * lineHeight);
        rect = EditorGUI.IndentedRect(rect);

        //make the texture render as a square, fitted to the space allocated for it
        float size = Mathf.Min(rect.width, rect.height);
        rect.width = size;
        rect.height = size;

        //if the texture should be clickable
        if (clickable)
        {
            //add an invisible button underneath it that selects the texture in the inspector
            if (GUI.Button(rect, GUIContent.none))
            {
                Selection.activeObject = texture;
            }
        }

        //render the texture with transparency
        EditorGUI.DrawTextureTransparent(rect, texture);
    }

    //starts a foldout with a dark tinted background and return if it is open
    public static bool StartFoldout(ref bool isFoldoutOpen, string name)
    {
        //get a rect that encloses the vertical span of the foldout
        Rect background = EditorGUILayout.BeginVertical();
        background.xMin -= sFoldoutIndentBackgroundCorrection; //give the text some breathing room

        //draw a dark background for the foldout
        EditorGUI.DrawRect(EditorGUI.IndentedRect(background), sBackgroundColor);

        EditorGUILayout.Space();

        //add the foldout header
        GUIStyle foldoutHeaderStyle = EditorStyles.foldout;
        foldoutHeaderStyle.fontStyle = FontStyle.Bold;
        isFoldoutOpen = EditorGUILayout.Foldout(isFoldoutOpen, name, true, foldoutHeaderStyle);

        EditorGUILayout.Space();

        if (isFoldoutOpen)
        {
            //indent the contents inside the foldout
            EditorGUI.indentLevel++;
        }
        else
        {
            //end the foldout background immediately if it is closed
            EditorGUILayout.EndVertical();
        }

        return isFoldoutOpen;
    }

    //ends a foldout started with StartFoldout()
    public static void EndFoldout()
    {
        EditorGUILayout.Space();

        EditorGUI.indentLevel--;
        EditorGUILayout.EndVertical();
    }
}

//these wrappers allow the shader GUI to be able to open the premium tools without causing compiler errors when if they don't exist in the project

public abstract class FeathersAndFurCoatPaintingToolWrapper : EditorWindow
{
    public abstract void SetTarget(Material targetMaterial, Renderer targetRenderer);
}

public abstract class FeathersAndFurClothingMaskEditorWrapper : EditorWindow
{
    public abstract void SetTarget(Material targetMaterial, Renderer targetRenderer, bool bitmaskMode);
}