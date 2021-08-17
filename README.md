# Waterflow Shading Documentation

## Feature

- The ripples are simulated in two layers of Voronoi noise with parallel movement (one is the base and one is the highlight) , giving the final render a more dynamic and realistic look. 
- The vertex movement is simulated based on Perlin noise for a smoother animation. 
- The lightness of the surface texture and the intensity of the reflection are adjusted automatically to the angle of the directional light. (Adjust the slider in the demo scene to see the effect)
- The shader support cartoon style with certain setup of material properties. (See WaterFlowCartoon in the demo scene)

## Material Properties

### Base Color

| Base Color Properties | Description                                      |
|-----------------------|--------------------------------------------------|
| Color Tint            | Multiplicative mixing of color with main texture |
| Base Texture          | Static base texture of the water surface         |