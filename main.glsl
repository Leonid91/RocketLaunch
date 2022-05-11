void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;    
    vec4 col_a = texture(iChannel0, uv);
    vec4 col_b = texture(iChannel1, uv); 
    fragColor = mix (col_b, col_a, col_a.a);
    //fragColor = mix (col_b, col_a, 1.);
    //fragColor = col_a;
}