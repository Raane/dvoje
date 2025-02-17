uniform float frame;
uniform sampler2D tDiffuse;

varying vec2 vUv;






//-----------------------------------------------------------------------------
// Simple test/port of Mercury's SDF GLSL library: http://mercury.sexy/hg_sdf/
// by Tom '2015
// Disclaimer:
//   The library is done by Mercury team for OpenGL 4+ (look below),
//   not me, and this is just an unofficial port.
//-----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////
//
//                           HG_SDF
//
//     GLSL LIBRARY FOR BUILDING SIGNED DISTANCE BOUNDS
//
//     version 2015-12-15 (initial release)
//
//     Check http://mercury.sexy/hg_sdf for updates
//     and usage examples. Send feedback to spheretracing@mercury.sexy.
//
//     Brought to you by MERCURY http://mercury.sexy
//
//
//
// Released as Creative Commons Attribution-NonCommercial (CC BY-NC)
//
////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////
//
//             HELPER FUNCTIONS/MACROS
//
////////////////////////////////////////////////////////////////

#define PI 3.14159265
#define TAU (2*PI)
#define PHI (1.618033988749895)
     // PHI (sqrt(5)*0.5 + 0.5)

// Clamp to [0,1] - this operation is free under certain circumstances.
// For further information see
// http://www.humus.name/Articles/Persson_LowLevelThinking.pdf and
// http://www.humus.name/Articles/Persson_LowlevelShaderOptimization.pdf
//#define saturate(x) clamp(x, 0., 1.)

// Sign function that doesn't return 0
float sgn(float x) {
  return (x<0.)?-1.:1.;
}

float square (float x) {
  return x*x;
}

vec2 square (vec2 x) {
  return x*x;
}

vec3 square (vec3 x) {
  return x*x;
}

float lengthSqr(vec3 x) {
  return dot(x, x);
}


// Maximum/minumum elements of a vector
float vmax(vec2 v) {
  return max(v.x, v.y);
}

float vmax(vec3 v) {
  return max(max(v.x, v.y), v.z);
}

float vmax(vec4 v) {
  return max(max(v.x, v.y), max(v.z, v.w));
}

float vmin(vec2 v) {
  return min(v.x, v.y);
}

float vmin(vec3 v) {
  return min(min(v.x, v.y), v.z);
}

float vmin(vec4 v) {
  return min(min(v.x, v.y), min(v.z, v.w));
}




////////////////////////////////////////////////////////////////
//
//             PRIMITIVE DISTANCE FUNCTIONS
//
////////////////////////////////////////////////////////////////
//
// Conventions:
//
// Everything that is a distance function is called fSomething.
// The first argument is always a point in 2 or 3-space called <p>.
// Unless otherwise noted, (if the object has an intrinsic "up"
// side or direction) the y axis is "up" and the object is
// centered at the origin.
//
////////////////////////////////////////////////////////////////

float fSphere(vec3 p, float r) {
  return length(p) - r;
}

// Plane with normal n (n is normalized) at some distance from the origin
float fPlane(vec3 p, vec3 n, float distanceFromOrigin) {
  return dot(p, n) + distanceFromOrigin;
}

// Cheap Box: distance to corners is overestimated
float fBoxCheap(vec3 p, vec3 b) { //cheap box
  return vmax(abs(p) - b);
}

// Box: correct distance to corners
float fBox(vec3 p, vec3 b) {
  vec3 d = abs(p) - b;
  return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

// Same as above, but in two dimensions (an endless box)
float fBox2Cheap(vec2 p, vec2 b) {
  return vmax(abs(p)-b);
}

float fBox2(vec2 p, vec2 b) {
  vec2 d = abs(p) - b;
  return length(max(d, vec2(0))) + vmax(min(d, vec2(0)));
}


// Endless "corner"
float fCorner (vec2 p) {
  return length(max(p, vec2(0))) + vmax(min(p, vec2(0)));
}

// Blobby ball object. You've probably seen it somewhere. This is not a correct distance bound, beware.
float fBlob(vec3 p) {
  p = abs(p);
  if (p.x < max(p.y, p.z)) p = p.yzx;
  if (p.x < max(p.y, p.z)) p = p.yzx;
  float b = max(max(max(
    dot(p, normalize(vec3(1, 1, 1))),
    dot(p.xz, normalize(vec2(PHI+1., 1)))),
    dot(p.yx, normalize(vec2(1, PHI)))),
    dot(p.xz, normalize(vec2(1, PHI))));
  float l = length(p);
  return l - 1.5 - 0.2 * (1.5 / 2.)* cos(min(sqrt(1.01 - b / l)*(PI / 0.25), PI));
}

// Cylinder standing upright on the xz plane
float fCylinder(vec3 p, float r, float height) {
  float d = length(p.xz) - r;
  d = max(d, abs(p.y) - height);
  return d;
}

// Capsule: A Cylinder with round caps on both sides
float fCapsule(vec3 p, float r, float c) {
  return mix(length(p.xz) - r, length(vec3(p.x, abs(p.y) - c, p.z)) - r, step(c, abs(p.y)));
}

// Distance to line segment between <a> and <b>, used for fCapsule() version 2below
float fLineSegment(vec3 p, vec3 a, vec3 b) {
  vec3 ab = b - a;
  float t = saturate(dot(p - a, ab) / dot(ab, ab));
  return length((ab*t + a) - p);
}

// Capsule version 2: between two end points <a> and <b> with radius r 
float fCapsule(vec3 p, vec3 a, vec3 b, float r) {
  return fLineSegment(p, a, b) - r;
}

// Torus in the XZ-plane
float fTorus(vec3 p, float smallRadius, float largeRadius) {
  return length(vec2(length(p.xz) - largeRadius, p.y)) - smallRadius;
}

// A circle line. Can also be used to make a torus by subtracting the smaller radius of the torus.
float fCircle(vec3 p, float r) {
  float l = length(p.xz) - r;
  return length(vec2(p.y, l));
}

// A circular disc with no thickness (i.e. a cylinder with no height).
// Subtract some value to make a flat disc with rounded edge.
float fDisc(vec3 p, float r) {
 float l = length(p.xz) - r;
  return l < 0. ? abs(p.y) : length(vec2(p.y, l));
}

// Hexagonal prism, circumcircle variant
float fHexagonCircumcircle(vec3 p, vec2 h) {
  vec3 q = abs(p);
  return max(q.y - h.y, max(q.x*sqrt(3.)*0.5 + q.z*0.5, q.z) - h.x);
  //this is mathematically equivalent to this line, but less efficient:
  //return max(q.y - h.y, max(dot(vec2(cos(PI/3), sin(PI/3)), q.zx), q.z) - h.x);
}

// Hexagonal prism, incircle variant
float fHexagonIncircle(vec3 p, vec2 h) {
  return fHexagonCircumcircle(p, vec2(h.x*sqrt(3.)*0.5, h.y));
}

// Cone with correct distances to tip and base circle. Y is up, 0 is in the middle of the base.
float fCone(vec3 p, float radius, float height) {
  vec2 q = vec2(length(p.xz), p.y);
  vec2 tip = q - vec2(0, height);
  vec2 mantleDir = normalize(vec2(height, radius));
  float mantle = dot(tip, mantleDir);
  float d = max(mantle, -q.y);
  float projected = dot(tip, vec2(mantleDir.y, -mantleDir.x));
  
  // distance to tip
  if ((q.y > height) && (projected < 0.)) {
    d = max(d, length(tip));
  }
  
  // distance to base ring
  if ((q.x > radius) && (projected > length(vec2(height, radius)))) {
    d = max(d, length(q - vec2(radius, 0)));
  }
  return d;
}

//
// "Generalized Distance Functions" by Akleman and Chen.
// see the Paper at https://www.viz.tamu.edu/faculty/ergun/research/implicitmodeling/papers/sm99.pdf
//
// This set of constants is used to construct a large variety of geometric primitives.
// Indices are shifted by 1 compared to the paper because we start counting at Zero.
// Some of those are slow whenever a driver decides to not unroll the loop,
// which seems to happen for fIcosahedron und fTruncatedIcosahedron on nvidia 350.12 at least.
// Specialized implementations can well be faster in all cases.
//

// Macro based version for GLSL 1.2 / ES 2.0 by Tom

#define GDFVector0 vec3(1, 0, 0)
#define GDFVector1 vec3(0, 1, 0)
#define GDFVector2 vec3(0, 0, 1)

#define GDFVector3 normalize(vec3(1, 1, 1 ))
#define GDFVector4 normalize(vec3(-1, 1, 1))
#define GDFVector5 normalize(vec3(1, -1, 1))
#define GDFVector6 normalize(vec3(1, 1, -1))

#define GDFVector7 normalize(vec3(0, 1, PHI+1.))
#define GDFVector8 normalize(vec3(0, -1, PHI+1.))
#define GDFVector9 normalize(vec3(PHI+1., 0, 1))
#define GDFVector10 normalize(vec3(-PHI-1., 0, 1))
#define GDFVector11 normalize(vec3(1, PHI+1., 0))
#define GDFVector12 normalize(vec3(-1, PHI+1., 0))

#define GDFVector13 normalize(vec3(0, PHI, 1))
#define GDFVector14 normalize(vec3(0, -PHI, 1))
#define GDFVector15 normalize(vec3(1, 0, PHI))
#define GDFVector16 normalize(vec3(-1, 0, PHI))
#define GDFVector17 normalize(vec3(PHI, 1, 0))
#define GDFVector18 normalize(vec3(-PHI, 1, 0))

#define fGDFBegin float d = 0.;

// Version with variable exponent.
// This is slow and does not produce correct distances, but allows for bulging of objects.
#define fGDFExp(v) d += pow(abs(dot(p, v)), e);

// Version with without exponent, creates objects with sharp edges and flat faces
#define fGDF(v) d = max(d, abs(dot(p, v)));

#define fGDFExpEnd return pow(d, 1./e) - r;
#define fGDFEnd return d - r;

// Primitives follow:

float fOctahedron(vec3 p, float r, float e) {
  fGDFBegin
    fGDFExp(GDFVector3) fGDFExp(GDFVector4) fGDFExp(GDFVector5) fGDFExp(GDFVector6)
    fGDFExpEnd
}

float fDodecahedron(vec3 p, float r, float e) {
  fGDFBegin
    fGDFExp(GDFVector13) fGDFExp(GDFVector14) fGDFExp(GDFVector15) fGDFExp(GDFVector16)
    fGDFExp(GDFVector17) fGDFExp(GDFVector18)
    fGDFExpEnd
}

float fIcosahedron(vec3 p, float r, float e) {
  fGDFBegin
    fGDFExp(GDFVector3) fGDFExp(GDFVector4) fGDFExp(GDFVector5) fGDFExp(GDFVector6)
    fGDFExp(GDFVector7) fGDFExp(GDFVector8) fGDFExp(GDFVector9) fGDFExp(GDFVector10)
    fGDFExp(GDFVector11) fGDFExp(GDFVector12)
    fGDFExpEnd
}

float fTruncatedOctahedron(vec3 p, float r, float e) {
  fGDFBegin
    fGDFExp(GDFVector0) fGDFExp(GDFVector1) fGDFExp(GDFVector2) fGDFExp(GDFVector3)
    fGDFExp(GDFVector4) fGDFExp(GDFVector5) fGDFExp(GDFVector6)
    fGDFExpEnd
}

float fTruncatedIcosahedron(vec3 p, float r, float e) {
  fGDFBegin
    fGDFExp(GDFVector3) fGDFExp(GDFVector4) fGDFExp(GDFVector5) fGDFExp(GDFVector6)
    fGDFExp(GDFVector7) fGDFExp(GDFVector8) fGDFExp(GDFVector9) fGDFExp(GDFVector10)
    fGDFExp(GDFVector11) fGDFExp(GDFVector12) fGDFExp(GDFVector13) fGDFExp(GDFVector14)
    fGDFExp(GDFVector15) fGDFExp(GDFVector16) fGDFExp(GDFVector17) fGDFExp(GDFVector18)
    fGDFExpEnd
}

float fOctahedron(vec3 p, float r) {
  fGDFBegin
    fGDF(GDFVector3) fGDF(GDFVector4) fGDF(GDFVector5) fGDF(GDFVector6)
    fGDFEnd
}

float fDodecahedron(vec3 p, float r) {
    fGDFBegin
    fGDF(GDFVector13) fGDF(GDFVector14) fGDF(GDFVector15) fGDF(GDFVector16)
    fGDF(GDFVector17) fGDF(GDFVector18)
    fGDFEnd
}

float fIcosahedron(vec3 p, float r) {
  fGDFBegin
    fGDF(GDFVector3) fGDF(GDFVector4) fGDF(GDFVector5) fGDF(GDFVector6)
    fGDF(GDFVector7) fGDF(GDFVector8) fGDF(GDFVector9) fGDF(GDFVector10)
    fGDF(GDFVector11) fGDF(GDFVector12)
    fGDFEnd
}

float fTruncatedOctahedron(vec3 p, float r) {
  fGDFBegin
    fGDF(GDFVector0) fGDF(GDFVector1) fGDF(GDFVector2) fGDF(GDFVector3)
    fGDF(GDFVector4) fGDF(GDFVector5) fGDF(GDFVector6)
    fGDFEnd
}

float fTruncatedIcosahedron(vec3 p, float r) {
  fGDFBegin
    fGDF(GDFVector3) fGDF(GDFVector4) fGDF(GDFVector5) fGDF(GDFVector6)
    fGDF(GDFVector7) fGDF(GDFVector8) fGDF(GDFVector9) fGDF(GDFVector10)
    fGDF(GDFVector11) fGDF(GDFVector12) fGDF(GDFVector13) fGDF(GDFVector14)
    fGDF(GDFVector15) fGDF(GDFVector16) fGDF(GDFVector17) fGDF(GDFVector18)
    fGDFEnd
}


////////////////////////////////////////////////////////////////
//
//                DOMAIN MANIPULATION OPERATORS
//
////////////////////////////////////////////////////////////////
//
// Conventions:
//
// Everything that modifies the domain is named pSomething.
//
// Many operate only on a subset of the three dimensions. For those,
// you must choose the dimensions that you want manipulated
// by supplying e.g. <p.x> or <p.zx>
//
// <inout p> is always the first argument and modified in place.
//
// Many of the operators partition space into cells. An identifier
// or cell index is returned, if possible. This return value is
// intended to be optionally used e.g. as a random seed to change
// parameters of the distance functions inside the cells.
//
// Unless stated otherwise, for cell index 0, <p> is unchanged and cells
// are centered on the origin so objects don't have to be moved to fit.
//
//
////////////////////////////////////////////////////////////////



// Rotate around a coordinate axis (i.e. in a plane perpendicular to that axis) by angle <a>.
// Read like this: R(p.xz, a) rotates "x towards z".
// This is fast if <a> is a compile-time constant and slower (but still practical) if not.
void pR(inout vec2 p, float a) {
  p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

// Shortcut for 45-degrees rotation
void pR45(inout vec2 p) {
  p = (p + vec2(p.y, -p.x))*sqrt(0.5);
}

// Repeat space along one axis. Use like this to repeat along the x axis:
// <float cell = pMod1(p.x,5);> - using the return value is optional.
float pMod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

// Same, but mirror every second cell so they match at the boundaries
float pModMirror1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize,size) - halfsize;
  p *= mod(c, 2.0)*2. - 1.;
  return c;
}

// Repeat the domain only in positive direction. Everything in the negative half-space is unchanged.
float pModSingle1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  if (p >= 0.)
    p = mod(p + halfsize, size) - halfsize;
  return c;
}

// Repeat only a few times: from indices <start> to <stop> (similar to above, but more flexible)
float pModInterval1(inout float p, float size, float start, float stop) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p+halfsize, size) - halfsize;
  if (c > stop) { //yes, this might not be the best thing numerically.
    p += size*(c - stop);
    c = stop;
  }
  if (c <start) {
    p += size*(c - start);
    c = start;
  }
  return c;
}


// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
float pModPolar(inout vec2 p, float repetitions) {
  float angle = 2.*PI/repetitions;
  float a = atan(p.y, p.x) + angle/2.;
  float r = length(p);
  float c = floor(a/angle);
  a = mod(a,angle) - angle/2.;
  p = vec2(cos(a), sin(a))*r;
  // For an odd number of repetitions, fix cell index of the cell in -x direction
  // (cell index would be e.g. -5 and 5 in the two halves of the cell):
  if (abs(c) >= (repetitions/2.)) c = abs(c);
  return c;
}

// Repeat in two dimensions
vec2 pMod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

// Same, but mirror every second cell so all boundaries match
vec2 pModMirror2(inout vec2 p, vec2 size) {
  vec2 halfsize = size*0.5;
  vec2 c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  p *= mod(c,vec2(2))*2. - vec2(1);
  return c;
}

// Same, but mirror every second cell at the diagonal as well
vec2 pModGrid2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5, size) - size*0.5;
  p *= mod(c,vec2(2))*2. - vec2(1);
  p -= size/2.;
  if (p.x > p.y) p.xy = p.yx;
  return floor(c/2.);
}

// Repeat in three dimensions
vec3 pMod3(inout vec3 p, vec3 size) {
  vec3 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5, size) - size*0.5;
  return c;
}

// Mirror at an axis-aligned plane which is at a specified distance <dist> from the origin.
float pMirror (inout float p, float dist) {
  float s = sign(p);
  p = abs(p)-dist;
  return s;
}

// Mirror in both dimensions and at the diagonal, yielding one eighth of the space.
// translate by dist before mirroring.
vec2 pMirrorOctant (inout vec2 p, vec2 dist) {
  vec2 s = sign(p);
  pMirror(p.x, dist.x);
  pMirror(p.y, dist.y);
  if (p.y > p.x)
    p.xy = p.yx;
  return s;
}

// Reflect space at a plane
float pReflect(inout vec3 p, vec3 planeNormal, float offset) {
  float t = dot(p, planeNormal)+offset;
  if (t < 0.) {
    p = p - (2.*t)*planeNormal;
  }
  return sign(t);
}


////////////////////////////////////////////////////////////////
//
//             OBJECT COMBINATION OPERATORS
//
////////////////////////////////////////////////////////////////
//
// We usually need the following boolean operators to combine two objects:
// Union: OR(a,b)
// Intersection: AND(a,b)
// Difference: AND(a,!b)
// (a and b being the distances to the objects).
//
// The trivial implementations are min(a,b) for union, max(a,b) for intersection
// and max(a,-b) for difference. To combine objects in more interesting ways to
// produce rounded edges, chamfers, stairs, etc. instead of plain sharp edges we
// can use combination operators. It is common to use some kind of "smooth minimum"
// instead of min(), but we don't like that because it does not preserve Lipschitz
// continuity in many cases.
//
// Naming convention: since they return a distance, they are called fOpSomething.
// The different flavours usually implement all the boolean operators above
// and are called fOpUnionRound, fOpIntersectionRound, etc.
//
// The basic idea: Assume the object surfaces intersect at a right angle. The two
// distances <a> and <b> constitute a new local two-dimensional coordinate system
// with the actual intersection as the origin. In this coordinate system, we can
// evaluate any 2D distance function we want in order to shape the edge.
//
// The operators below are just those that we found useful or interesting and should
// be seen as examples. There are infinitely more possible operators.
//
// They are designed to actually produce correct distances or distance bounds, unlike
// popular "smooth minimum" operators, on the condition that the gradients of the two
// SDFs are at right angles. When they are off by more than 30 degrees or so, the
// Lipschitz condition will no longer hold (i.e. you might get artifacts). The worst
// case is parallel surfaces that are close to each other.
//
// Most have a float argument <r> to specify the radius of the feature they represent.
// This should be much smaller than the object size.
//
// Some of them have checks like "if ((-a < r) && (-b < r))" that restrict
// their influence (and computation cost) to a certain area. You might
// want to lift that restriction or enforce it. We have left it as comments
// in some cases.
//
// usage example:
//
// float fTwoBoxes(vec3 p) {
//   float box0 = fBox(p, vec3(1));
//   float box1 = fBox(p-vec3(1), vec3(1));
//   return fOpUnionChamfer(box0, box1, 0.2);
// }
//
////////////////////////////////////////////////////////////////


// The "Chamfer" flavour makes a 45-degree chamfered edge (the diagonal of a square of size <r>):
float fOpUnionChamfer(float a, float b, float r) {
  float m = min(a, b);
  //if ((a < r) && (b < r)) {
    return min(m, (a - r + b)*sqrt(0.5));
  //} else {
    return m;
  //}
}

// Intersection has to deal with what is normally the inside of the resulting object
// when using union, which we normally don't care about too much. Thus, intersection
// implementations sometimes differ from union implementations.
float fOpIntersectionChamfer(float a, float b, float r) {
  float m = max(a, b);
  if (r <= 0.) return m;
  if (((-a < r) && (-b < r)) || (m < 0.)) {
    return max(m, (a + r + b)*sqrt(0.5));
  } else {
    return m;
  }
}

// Difference can be built from Intersection or Union:
float fOpDifferenceChamfer (float a, float b, float r) {
  return fOpIntersectionChamfer(a, -b, r);
}

// The "Round" variant uses a quarter-circle to join the two objects smoothly:
float fOpUnionRound(float a, float b, float r) {
  float m = min(a, b);
  if ((a < r) && (b < r) ) {
    return min(m, r - sqrt((r-a)*(r-a) + (r-b)*(r-b)));
  } else {
   return m;
  }
}

float fOpIntersectionRound(float a, float b, float r) {
  float m = max(a, b);
  if ((-a < r) && (-b < r)) {
    return max(m, -(r - sqrt((r+a)*(r+a) + (r+b)*(r+b))));
  } else {
    return m;
  }
}

float fOpDifferenceRound (float a, float b, float r) {
  return fOpIntersectionRound(a, -b, r);
}


// The "Columns" flavour makes n-1 circular columns at a 45 degree angle:
float fOpUnionColumns(float a, float b, float r, float n) {
  if ((a < r) && (b < r)) {
    vec2 p = vec2(a, b);
    float columnradius = r*sqrt(2.)/((n-1.)*2.+sqrt(2.));
    pR45(p);
    p.x -= sqrt(2.)/2.*r;
    p.x += columnradius*sqrt(2.);
    if (mod(n,2.) == 1.) {
      p.y += columnradius;
    }
    // At this point, we have turned 45 degrees and moved at a point on the
    // diagonal that we want to place the columns on.
    // Now, repeat the domain along this direction and place a circle.
    pMod1(p.y, columnradius*2.);
    float result = length(p) - columnradius;
    result = min(result, p.x);
    result = min(result, a);
    return min(result, b);
  } else {
    return min(a, b);
  }
}

float fOpDifferenceColumns(float a, float b, float r, float n) {
  a = -a;
  float m = min(a, b);
  //avoid the expensive computation where not needed (produces discontinuity though)
  if ((a < r) && (b < r)) {
    vec2 p = vec2(a, b);
    float columnradius = r*sqrt(2.)/n/2.0;
    columnradius = r*sqrt(2.)/((n-1.)*2.+sqrt(2.));

    pR45(p);
    p.y += columnradius;
    p.x -= sqrt(2.)/2.*r;
    p.x += -columnradius*sqrt(2.)/2.;

    if (mod(n,2.) == 1.) {
      p.y += columnradius;
    }
    pMod1(p.y,columnradius*2.);

    float result = -length(p) + columnradius;
    result = max(result, p.x);
    result = min(result, a);
    return -min(result, b);
  } else {
    return -m;
  }
}

float fOpIntersectionColumns(float a, float b, float r, float n) {
  return fOpDifferenceColumns(a,-b,r, n);
}

// The "Stairs" flavour produces n-1 steps of a staircase:
float fOpUnionStairs(float a, float b, float r, float n) {
  float d = min(a, b);
  vec2 p = vec2(a, b);
  pR45(p);
  p = p.yx - vec2((r-r/n)*0.5*sqrt(2.));
  p.x += 0.5*sqrt(2.)*r/n;
  float x = r*sqrt(2.)/n;
  pMod1(p.x, x);
  d = min(d, p.y);
  pR45(p);
  return min(d, vmax(p -vec2(0.5*r/n)));
}

// We can just call Union since stairs are symmetric.
float fOpIntersectionStairs(float a, float b, float r, float n) {
  return -fOpUnionStairs(-a, -b, r, n);
}

float fOpDifferenceStairs(float a, float b, float r, float n) {
  return -fOpUnionStairs(-a, b, r, n);
}

// This produces a cylindical pipe that runs along the intersection.
// No objects remain, only the pipe. This is not a boolean operator.
float fOpPipe(float a, float b, float r) {
  return length(vec2(a, b)) - r;
}

////////////////////////////////////////////////////////////////
// The end of HG_SDF library
////////////////////////////////////////////////////////////////




//------------------------------------------------------------------------
// Here rather hacky and very basic sphere tracer, feel free to replace.
//------------------------------------------------------------------------

// fField(p) is the final SDF definition, declared at the very bottom
const vec3 iResolution = vec3(1., 1., 1.);

const int iterations = 200;
const float dist_eps = .001;
const float ray_max = 200.0;
const float fog_density = .03;

const float cam_dist = 5.;
const float iTime = 0.;

float fField(vec3 p)
{
   float towerspacing = 3.5;
   vec2 c = pMod2(p.xz, vec2(towerspacing));
   float towerfaces = 5. + floor(2. * sin(9. * c.x + 2.12345 * c.y));
   pModPolar(p.xz, towerfaces);
   
   //pMirrorOctant(p.xz, vec2(.4, .4));
   p.y += 1.;
   float basewidth = 0.5 + .2 * sin(1. * c.x + 5.12345 * c.y);
   float wallthinkness = .05 + .02 * sin(2. *c.x + 6.12345 * c.y);
   float mainfaceheight = 1. + 1. * sin(3. *c.x + 6.12345 * c.y);
   float balconywidth = 0.2 + .15 * sin(4. *c.x + 7.12345 * c.y);
   float balconyheight = 0.2 + .1 * sin(5. *c.x + 8.12345 * c.y);
   float breastguardheight = 0.15 + .1 * sin(c.x + 0.12345 * c.y);
   p.x -= basewidth;
   float mainface = fBox2(p.xy,vec2(wallthinkness, mainfaceheight));
   p.y -= mainfaceheight;
   p.x -= balconywidth;
   float balconyfloor = fBox2(p.xy,vec2(balconywidth, wallthinkness));
   p.y -= balconyheight;
   p.x -= balconywidth;
   float balconywall = fBox2(p.xy,vec2(wallthinkness, balconyheight));
   p.y -= balconyheight;
   pMod1(p.z, wallthinkness * 4.);
   float breastguard = fBox(p,vec3(.1, breastguardheight, wallthinkness));
   float wall = fOpUnionStairs(mainface, balconyfloor, .2, 3.);
   wall = fOpUnionStairs(wall, balconywall, .2, 3.);
   wall = min(wall, breastguard);
   return wall;
}

vec3 dNormal(vec3 p)
{
   const vec2 e = vec2(.005,0);
   return normalize(vec3(
      fField(p + e.xyy) - fField(p - e.xyy),
      fField(p + e.yxy) - fField(p - e.yxy),
      fField(p + e.yyx) - fField(p - e.yyx) ));
}

vec4 trace(vec3 ray_start, vec3 ray_dir)
{
   float ray_len = 0.0;
   vec3 p = ray_start;
   for(int i=0; i<iterations; ++i) {
      float dist = fField(p) / 4.;
      if (dist < dist_eps) break;
      if (ray_len > ray_max) return vec4(0.0);
      p += dist*ray_dir;
      ray_len += dist;
   }
   return vec4(p, 1.0);
}

// abs(0+0-1)=1
// abs(1+0-1)=0
// abs(0+1-1)=0
// abs(1+1-1)=1
float xnor(float x, in float y) { return abs(x+y-1.0); }

vec4 checker_texture(vec3 pos, float sample_size)
{
   pos = pos*8.0 + .5;
   vec3 cell = step(1.0,mod(pos,2.0));
   float checker = xnor(xnor(cell.x,cell.y),cell.z);
   vec4 col = mix(vec4(.4),vec4(.5),checker);
   float fade = 1.-min(1.,sample_size*24.); // very fake "AA"
   col = mix(vec4(.5),col,fade);
   pos = abs(fract(pos)-.5);
   float d = max(max(pos.x,pos.y),pos.z);
   d = smoothstep(.45,.5,d)*fade;
   return mix(col,vec4(0.0),d);
}

vec3 sky_color(vec3 ray_dir, vec3 light_dir)
{
   float d = max(0.,dot(ray_dir,light_dir));
   float d2 = light_dir.y*.7+.3;
   vec3 base_col;
   base_col = mix(vec3(.3),vec3((ray_dir.y<0.)?0.:1.),abs(ray_dir.y));
   return base_col*d2;
}

vec4 debug_plane(vec3 ray_start, vec3 ray_dir, float cut_plane, inout float ray_len)
{
    // Fancy lighty debug plane
    if (ray_start.y > cut_plane && ray_dir.y < 0.) {
       float d = (ray_start.y - cut_plane) / -ray_dir.y;
       if (d < ray_len) {
           vec3 hit = ray_start + ray_dir*d;
           float hit_dist = fField(hit);
           float iso = fract(hit_dist*5.0);
           vec3 dist_color = mix(vec3(.2,.4,.6),vec3(.2,.2,.4),iso);
           dist_color *= 1.0/(max(0.0,hit_dist)+.001);
           ray_len = d;
           return vec4(dist_color,.1);
      }
   }
   return vec4(0);
}

vec3 shade(vec3 ray_start, vec3 ray_dir, vec3 light_dir, vec4 hit)
{
   vec3 fog_color = sky_color(ray_dir, light_dir);
   
   float ray_len;
   vec3 color;
   if (hit.w == 0.0) {
      ray_len = 1e16;
      color = fog_color;
   } else {
      vec3 dir = hit.xyz - ray_start;
      vec3 norm = dNormal(hit.xyz);
      float diffuse = max(0.0, dot(norm, light_dir));
      float spec = max(0.0,dot(reflect(light_dir,norm),normalize(dir)));
      spec = pow(spec, 16.0)*.5;
       
      ray_len = length(dir);
   
      vec3 base_color = checker_texture(hit.xyz,ray_len/iResolution.y).xyz;
      color = mix(vec3(0.,.1,.3),vec3(1.,1.,.9),diffuse)*base_color +
         spec*vec3(1.,1.,.9);

      float fog_dist = ray_len;
      float fog = 1.0 - 1.0/exp(fog_dist*fog_density);
      color = mix(color, fog_color, fog);
   }
   
   
    
   float cut_plane0 = sin(iTime)*.15 - .8;
   for(int k=0; k<4; ++k) {
      vec4 dpcol = debug_plane(ray_start, ray_dir, cut_plane0+float(k)*.75, ray_len);
      //if (dpcol.w == 0.) continue;
      float fog_dist = ray_len;
      dpcol.w *= 1.0/exp(fog_dist*.05);
      //color = mix(color,dpcol.xyz,dpcol.w);
   }

   return color;
}

void mainImage(out vec4 fragColor, vec2 fragCoord)
{
   vec2 uv = (fragCoord.xy - iResolution.xy*0.5) / iResolution.y;
    
   vec3 light_dir = normalize(vec3(.5, 1.0, -.25));
   
   // Simple model-view matrix:
   float ang, si, co;
   ang = 1.;
   si = sin(ang); co = cos(ang);
   mat4 cam_mat = mat4(
      co, 0., si, 0.,
      0., 1., 0., 0.,
     -si, 0., co, 0.,
      0., 0., 0., 1.);
   ang = 1.; //iTime*.2;
   si = sin(ang); co = cos(ang);
   cam_mat = cam_mat * mat4(
      1., 0., 0., 0.,
      0., co, si, 0.,
      0.,-si, co, 0.,
      0., 0., 0., 1.);

   vec3 pos = vec3(cam_mat*vec4(0., 0., -cam_dist, 1.0));
   vec3 dir = normalize(vec3(cam_mat*vec4(uv, 1., 0.)));
   
   vec3 color = shade(pos, dir, light_dir, trace(pos, dir));
   color = pow(color,vec3(.44));
   fragColor = vec4(color, 1.);
}

//------------------------------------------------------------------------
// Your custom SDF
//------------------------------------------------------------------------
/*
float fField(vec3 p)
{
   float towerspacing = 3.5;
   vec2 c = pMod2(p.xz, vec2(towerspacing));
   float towerfaces = 5. + floor(2. * sin(9. * c.x + 2.12345 * c.y));
   pModPolar(p.xz, towerfaces);
   
   //pMirrorOctant(p.xz, vec2(.4, .4));
   p.y += 1.;
   float basewidth = 0.5 + .2 * sin(1. * c.x + 5.12345 * c.y);
   float wallthinkness = .05 + .02 * sin(2. *c.x + 6.12345 * c.y);
   float mainfaceheight = 1. + 1. * sin(3. *c.x + 6.12345 * c.y);
   float balconywidth = 0.2 + .15 * sin(4. *c.x + 7.12345 * c.y);
   float balconyheight = 0.2 + .1 * sin(5. *c.x + 8.12345 * c.y);
   float breastguardheight = 0.15 + .1 * sin(c.x + 0.12345 * c.y);
   p.x -= basewidth;
   float mainface = fBox2(p.xy,vec2(wallthinkness, mainfaceheight));
   p.y -= mainfaceheight;
   p.x -= balconywidth;
   float balconyfloor = fBox2(p.xy,vec2(balconywidth, wallthinkness));
   p.y -= balconyheight;
   p.x -= balconywidth;
   float balconywall = fBox2(p.xy,vec2(wallthinkness, balconyheight));
   p.y -= balconyheight;
   pMod1(p.z, wallthinkness * 4.);
   float breastguard = fBox(p,vec3(.1, breastguardheight, wallthinkness));
   float wall = fOpUnionStairs(mainface, balconyfloor, .2, 3.);
   wall = fOpUnionStairs(wall, balconywall, .2, 3.);
   wall = min(wall, breastguard);
   return wall;
}
*/

void main() {
    vec4 output_color;
    mainImage(output_color, vUv);

    //gl_FragColor = vec4(vUv, 0.5 + 0.5 * sin(frame / 60.0), 1.0);
    gl_FragColor = output_color;
}
