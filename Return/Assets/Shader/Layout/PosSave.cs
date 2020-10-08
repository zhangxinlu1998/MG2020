using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PosSave : MonoBehaviour {
    Transform thisTransform;

    private Vector3[] beforePos = new Vector3[50];
    private int offsetPosIndex = 0;
    int beforePosIndex = 0;

    private Material mat;

    private void Start () {
        thisTransform = this.transform;
        beforePos[beforePosIndex] = thisTransform.position;
        beforePosIndex += 1;
        mat = this.GetComponentInChildren<MeshRenderer> ().sharedMaterial;
    }

    private void Update () {

        
        offsetPosIndex = mat.GetInt ("_Strength");
        mat.SetVector ("_KnifePos", thisTransform.position);

        beforePos[beforePosIndex] = thisTransform.position;
        if (beforePosIndex - offsetPosIndex >= 0)
            mat.SetVector ("_PastPos", beforePos[beforePosIndex - offsetPosIndex]);
        else
        mat.SetVector ("_PastPos", beforePos[beforePos.Length + beforePosIndex - offsetPosIndex]);
        beforePosIndex += 1;
        

        if (beforePosIndex == beforePos.Length)
            beforePosIndex = 0;

        
    }
}