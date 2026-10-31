varying vec4 color;
varying vec2 texcoord;

uniform sampler2D texture;
uniform sampler2D colortex4;

/* DRAWBUFFERS:4 */

void main() {
	gl_FragData[0] = vec4(texture2D(colortex4, texcoord).rgb, (texture2D(texture, texcoord).a * color.a));
}
