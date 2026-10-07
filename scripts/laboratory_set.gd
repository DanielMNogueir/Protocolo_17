class_name P17LaboratorySet
extends RefCounted
## Source coordinates measured on the original, unmodified environment image.
const TEXTURE: Texture2D = preload("res://assets/prologue/laboratory_set_v1.png")
const ORIGIN := Vector2(60,40)
const SCALE := 0.546875
const SOURCE_SIZE := Vector2(1536,1024)
const ART := Rect2(ORIGIN,SOURCE_SIZE*SCALE)
const FLOOR := [Vector2(730,310),Vector2(1485,664),Vector2(736,920),Vector2(42,544)]
const UNITS := [
 {"name":"cultivo esquerdo","outline":[Vector2(46,325),Vector2(113,281),Vector2(178,291),Vector2(213,332),Vector2(213,575),Vector2(155,601),Vector2(46,563)],"front":[Vector2(46,563),Vector2(155,601),Vector2(213,575)],"solid":[Vector2(49,540),Vector2(149,501),Vector2(211,543),Vector2(211,575),Vector2(155,596),Vector2(49,560)]},
 {"name":"bancada de calibração","outline":[Vector2(192,446),Vector2(256,422),Vector2(316,438),Vector2(317,462),Vector2(363,470),Vector2(387,493),Vector2(465,511),Vector2(549,559),Vector2(552,600),Vector2(582,616),Vector2(582,648),Vector2(459,695),Vector2(215,587),Vector2(196,546)],"front":[Vector2(215,587),Vector2(459,695),Vector2(582,648)],"solid":[Vector2(204,549),Vector2(325,508),Vector2(579,613),Vector2(579,645),Vector2(459,690),Vector2(214,583)]},
 {"name":"análise ambiental","outline":[Vector2(521,263),Vector2(600,235),Vector2(622,237),Vector2(622,198),Vector2(703,176),Vector2(703,220),Vector2(710,211),Vector2(710,169),Vector2(731,163),Vector2(740,175),Vector2(740,216),Vector2(771,249),Vector2(770,313),Vector2(576,390),Vector2(523,367)],"front":[Vector2(523,367),Vector2(576,390),Vector2(770,313)],"solid":[Vector2(524,337),Vector2(718,262),Vector2(770,285),Vector2(770,313),Vector2(577,385),Vector2(526,363)]},
 {"name":"núcleo de pesquisa","outline":[Vector2(793,213),Vector2(803,187),Vector2(835,165),Vector2(880,151),Vector2(887,55),Vector2(908,50),Vector2(914,151),Vector2(1000,164),Vector2(1030,197),Vector2(1029,232),Vector2(1035,416),Vector2(1055,419),Vector2(1074,449),Vector2(1088,448),Vector2(1105,486),Vector2(1100,546),Vector2(1066,567),Vector2(1015,588),Vector2(987,606),Vector2(937,605),Vector2(920,585),Vector2(856,582),Vector2(772,565),Vector2(704,531),Vector2(702,506),Vector2(721,480),Vector2(750,471),Vector2(752,411),Vector2(779,386),Vector2(782,258)],"front":[Vector2(704,531),Vector2(772,565),Vector2(856,582),Vector2(937,605),Vector2(987,606),Vector2(1066,567),Vector2(1100,546)],"solid":[Vector2(718,511),Vector2(801,474),Vector2(976,467),Vector2(1074,497),Vector2(1090,539),Vector2(979,598),Vector2(859,576),Vector2(773,557)]},
 {"name":"bancada de microscopia","outline":[Vector2(1201,326),Vector2(1267,301),Vector2(1337,324),Vector2(1350,379),Vector2(1344,488),Vector2(1304,539),Vector2(1200,493),Vector2(1181,452),Vector2(1186,437),Vector2(1165,418),Vector2(1177,397),Vector2(1202,403)],"front":[Vector2(1181,452),Vector2(1200,493),Vector2(1304,539),Vector2(1344,518)],"solid":[Vector2(1183,454),Vector2(1258,425),Vector2(1340,483),Vector2(1340,515),Vector2(1305,535),Vector2(1201,489)]},
 {"name":"cultivo direito","outline":[Vector2(1305,367),Vector2(1332,334),Vector2(1392,317),Vector2(1456,339),Vector2(1464,375),Vector2(1468,535),Vector2(1493,537),Vector2(1495,587),Vector2(1470,613),Vector2(1451,642),Vector2(1422,654),Vector2(1310,604),Vector2(1297,574),Vector2(1299,393)],"front":[Vector2(1310,604),Vector2(1422,654),Vector2(1451,642),Vector2(1495,587)],"solid":[Vector2(1303,568),Vector2(1406,528),Vector2(1488,573),Vector2(1488,588),Vector2(1420,648),Vector2(1310,597)]},
 {"name":"arquivo de emergência","outline":[Vector2(1085,612),Vector2(1111,587),Vector2(1163,602),Vector2(1177,615),Vector2(1177,717),Vector2(1124,741),Vector2(1107,727),Vector2(1106,750),Vector2(888,815),Vector2(836,788),Vector2(835,736),Vector2(851,718),Vector2(859,681),Vector2(905,669),Vector2(961,643),Vector2(1006,632),Vector2(1085,612)],"front":[Vector2(836,788),Vector2(888,815),Vector2(1106,750),Vector2(1124,741),Vector2(1177,717)],"solid":[Vector2(838,742),Vector2(1050,665),Vector2(1175,696),Vector2(1175,717),Vector2(1107,744),Vector2(888,810),Vector2(838,787)]},
]
const EXTRA_SOLIDS := [
 [Vector2(298,609),Vector2(313,597),Vector2(336,608),Vector2(338,628),Vector2(315,639),Vector2(296,626)],
 [Vector2(661,349),Vector2(675,341),Vector2(691,348),Vector2(691,361),Vector2(675,368),Vector2(660,360)],
 [Vector2(1052,737),Vector2(1068,727),Vector2(1087,738),Vector2(1087,760),Vector2(1068,771),Vector2(1051,756)],
 [Vector2(211,408),Vector2(335,362),Vector2(350,400),Vector2(234,446)],
 [Vector2(350,377),Vector2(520,313),Vector2(532,350),Vector2(365,413)],
]
static func point(source: Vector2) -> Vector2: return ORIGIN+source*SCALE
static func polygon(source: Array) -> PackedVector2Array:
 var result := PackedVector2Array()
 for p in source: result.append(point(p))
 return result
static func front_y(unit: Dictionary, x: float) -> float:
 var points: Array = unit.front
 var source_x := (x-ORIGIN.x)/SCALE
 if source_x<=points[0].x: return point(points[0]).y
 for n in range(1,points.size()):
  if source_x<=points[n].x:
   return point(points[n-1].lerp(points[n],inverse_lerp(points[n-1].x,points[n].x,source_x))).y
 return point(points[-1]).y
