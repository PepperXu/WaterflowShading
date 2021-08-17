using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UpdateLightAngle : MonoBehaviour
{
    public void SetLightAngle(float value)
    {
        transform.eulerAngles = new Vector3(90f*value, 0f, 0f);
    }
}
