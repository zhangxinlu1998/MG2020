using System.Collections;
using System.Collections.Generic;
using UnityEngine;
//[ExecuteInEditMode]
public class CreateGrass : MonoBehaviour
{
    public GameObject grassPrefab;
    public float length = 100f;
    public float width = 100f;
    public float density = 0.1f;
    void Start()
    {
        for(int i = 0;i < length;i ++)
        {
            for(int j = 0;j < width;j ++)
            {
                GameObject g = GameObject.Instantiate(grassPrefab);
                g.transform.SetParent(transform);
                Vector2 r = new Vector3(Random.Range(0f, density), Random.Range(0f, density));
                Vector3 grassPos = new Vector3(i * density - length * density * 0.5f + r.x, transform.position.y, j * density - width * density * 0.5f + r.y);
                g.transform.position = grassPos;
                g.transform.Rotate(new Vector3(0f,Random.Range(0f,360f), 0f));
            }
        }
    }

    void Update()
    {
        
    }
}
