using System.Collections;
using System.Collections.Generic;
using UnityEngine;
//[ExecuteInEditMode]
public class StickPosition : MonoBehaviour {

    Transform thisTransform;
    Vector3 defaultPos = Vector3.zero;
    Material Mat;


    void Start () {
        Mat = this.GetComponent<MeshRenderer>().sharedMaterial;
        thisTransform = this.transform;
        defaultPos = thisTransform.position;
        
    }


    void Update () {

        if (Input.GetMouseButtonDown (0)) {
            Ray ray = Camera.main.ScreenPointToRay (Input.mousePosition);

            RaycastHit hit;

            if (Physics.Raycast (ray, out hit)) {
                StopAllCoroutines ();
                StartCoroutine(PosChange(hit.point));   
            }
        }
    }

    IEnumerator PosChange(Vector3 dirPos)
    {
        yield return null;
        dirPos.y = defaultPos.y;
        thisTransform.position = dirPos;
    }


}