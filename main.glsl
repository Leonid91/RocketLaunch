void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;    
    vec4 col_a = texture(iChannel0, uv);
    vec4 col_b = texture(iChannel1, uv);
    vec4 col_c = texture(iChannel2, uv);
    
    float counter = 0.0;
    counter = iTime;
    if(counter < 5.){
        fragColor = mix (col_c, col_a, col_a.a);
    }
    else if(counter < 10. && counter > 5.){
        fragColor = mix (col_b, col_a, col_a.a);
    }

    
    //Use this for debug
    //fragColor = mix (col_b, col_a, col_a.a);
    //fragColor = mix (col_c, col_a, col_a.a);
    //fragColor = mix (col_b, col_a, 1.);
    //fragColor = col_c;
}