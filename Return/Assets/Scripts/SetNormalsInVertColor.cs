using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;


public class SetNormalsInVertColor : MonoBehaviour
{
    //设定平滑的角度阈值
    public int Degree;
    void Awake()
    {

        //获取当前挂载物体的Mesh
        Mesh mesh = new Mesh();
        if (GetComponent<SkinnedMeshRenderer>())
        {
            mesh = GetComponent<SkinnedMeshRenderer>().sharedMesh;
        }
        if (GetComponent<MeshFilter>())
        {
            mesh = GetComponent<MeshFilter>().sharedMesh;
        }
        Debug.Log(mesh.name);

        //声明一个三维数组srcmeshNormals，用来存放当前模型的原本法线信息
        Vector3[] srcmeshNormals = new Vector3[mesh.normals.Length];
        //遍历顶点，将原法线数据存入srcmeshNormals数组
        for (int i = 0; i < srcmeshNormals.Length; i++)
        {
            Vector3 Normal = new Vector3(0, 0, 0);

            for (int j = 0; j < srcmeshNormals.Length; j++)
            {
                if (mesh.vertices[j] == mesh.vertices[i])
                {
                    Normal = mesh.normals[i];
                }
            }
            srcmeshNormals[i] = Normal;
        }


        //对法线进行平滑计算，Degree越大，最后的平滑效果越好，但是也会有较大偏差
        mesh.RecalculateNormals(Degree);


        //再声明一个数组，用来存放平滑后的法线数据
        Vector3[] meshNormals = new Vector3[mesh.normals.Length];
        //遍历所有法线，存入该数组
        for (int i = 0; i < meshNormals.Length; i++)
        {
            Vector3 Normal = new Vector3(0, 0, 0);

            for (int j = 0; j < meshNormals.Length; j++)
            {
                if (mesh.vertices[j] == mesh.vertices[i])
                {
                    Normal = mesh.normals[i];
                }
            }
            meshNormals[i] = Normal;
        }



        //新建一个颜色数组把光滑处理后的法线值存入其中
        Color[] meshColors = new Color[mesh.colors.Length];
        for (int i = 0; i < meshColors.Length; i++)
        {
            meshColors[i].r = meshNormals[i].x ;
            meshColors[i].g = meshNormals[i].y ;
            meshColors[i].b = meshNormals[i].z ;
            //meshColors[i].a = srcmeshNormals[i].a;
        }

        //将颜色数组存入mesh的顶点色，将最开始未计算的法线重新填充mesh法线中，即可得到：法线正常，顶点色中是平滑的法线
        //配合shader外描边，使用顶点色数据进行法线外扩
        mesh.normals = srcmeshNormals;
        mesh.colors = meshColors;


        Debug.Log("Done");
    }
}
