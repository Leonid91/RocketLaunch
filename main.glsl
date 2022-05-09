void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    
    vec4 col = texture(iChannel0, uv);
    col = col + texture(iChannel1, uv);

    // Output to screen
    fragColor = col;

}