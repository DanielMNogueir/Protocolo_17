shader_type canvas_item;
render_mode unshaded;
uniform sampler2D field : filter_linear, repeat_disable;
uniform float scene_time=0.0;
uniform float restored=0.0;
uniform vec2 lamps[4];
void fragment() {
 vec2 world=UV*vec2(2560.0,1800.0);
 vec2 texel=vec2(1.0/640.0,1.0/450.0);
 vec4 data=texture(field,UV);
 float cast=data.r*0.4;
 cast+=(texture(field,UV+texel).r+texture(field,UV-texel).r)*0.15;
 cast+=(texture(field,UV+vec2(texel.x,-texel.y)).r+texture(field,UV+vec2(-texel.x,texel.y)).r)*0.15;
 float shade=clamp(cast*0.44+data.g*0.3,0.0,0.63);
 vec3 rgb=vec3(0.025,0.065,0.095)*shade;
 float alpha=shade;
 float ripple=sin(world.y*0.063+sin(world.x*0.024+scene_time*0.18)-scene_time*0.8);
 float sheen=pow(max(0.0,ripple),18.0)*data.b*data.a*0.07;
 rgb+=vec3(0.38,0.68,0.73)*sheen;
 alpha+=sheen;
 for(int i=0;i<4;i++){
  float active=step(float(i)+0.5,restored);
  float light=exp(-length((world-lamps[i])/vec2(110.0,65.0)))*0.115;
  vec3 emission=mix(vec3(0.85,0.52,0.23),vec3(0.25,0.8,0.76),active);
  light*=0.94+0.06*sin(scene_time*1.7+float(i));
  rgb+=emission*light;
  alpha+=light;
 }
 COLOR=vec4(rgb/max(alpha,0.001),min(alpha,0.69));
}
