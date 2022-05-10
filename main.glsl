void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    
    vec4 col_a = texture(iChannel0, uv);
    vec4 col_b = texture(iChannel1, uv);
    
    vec4 col;
   
    // Only clouds
    //col = mix (col_a, col_b, col_b.a);
    //col = mix (col_a, col_b, 1.0);
    
    // Only rocket
    //col = mix (col_b, col_a, col_b.a);
    //col = mix (col_b, col_a, 1.0);
    
    // Both but transparent
    col = mix (col_a, col_b, 0.5);

    // Output to screen
    fragColor = col;
}