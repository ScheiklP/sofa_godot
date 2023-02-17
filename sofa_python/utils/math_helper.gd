extends Reference


### Converts a unit quaternion into the corresponding XYZ euler angles (in degrees).
static func quat_to_euler(quat: Quat) -> Vector3:
	# see sofa_env/utils/math_helper.py
	var b = quat.x
	var c = quat.y
	var d = quat.z
	var a = quat.w

	var theta_3 = atan2(2.0 * (a * d - b * c), a*a + b*b - c*c - d*d)
	var theta_1 = atan2(2.0 * (a * b - c * d), a*a - b*b - c*c + d*d)
	var theta_2 = atan((2.0 * cos(theta_3) * (b * d + a * c)) / (a*a + b*b - c*c - d*d))

	return (180.0 / PI) * Vector3(theta_1, theta_2, theta_3)

## Converts XYZ euler angles into a normalized quaternion.
static func euler_to_quat(euler_angles: Vector3) -> Quat:
	var pts = (PI / 360.0) * euler_angles

	var cpan  = cos(pts.x)
	var ctilt = cos(pts.y)
	var cspin = cos(pts.z)

	var span  = sin(pts.x)
	var stilt = sin(pts.y)
	var sspin = sin(pts.z)
	
	var quat = Quat()
	quat.w = cpan * ctilt * cspin - span * stilt * sspin
	quat.x = cpan * stilt * sspin + span * ctilt * cspin
	quat.y = cpan * stilt * cspin - span * ctilt * sspin
	quat.z = cpan * ctilt * sspin + span * stilt * cspin
	return quat.normalized()


### Computes the rotation matrix for XYZ euler angles.
static func euler_to_rotation_matrix(euler_angles: Vector3) -> Basis:
	var c1 = cos(euler_angles.x * PI / 180.0)
	var c2 = cos(euler_angles.y * PI / 180.0)
	var c3 = cos(euler_angles.z * PI / 180.0)
	var s1 = sin(euler_angles.x * PI / 180.0)
	var s2 = sin(euler_angles.y * PI / 180.0)
	var s3 = sin(euler_angles.z * PI / 180.0)

	var x = Vector3( c2*c3,  c1*s3 + s1*s2*c3, s1*s3 - c1*s2*c3)
	var y = Vector3(-c2*s3,  c1*c3 - s1*s2*s3, s1*c3 + c1*s2*s3)
	var z = Vector3( s2   , -s1*c2           , c1*c2)

	return Basis(x, y, z)


static func rotation_matrix_to_euler(rotation_matrix: Basis) -> Vector3:
	# basis is column major, i.e. basis[0] yields the first column
	var r11 = rotation_matrix[0][0]
	var r12 = rotation_matrix[1][0]
	var r13 = rotation_matrix[2][0]

	var r23 = rotation_matrix[2][1]
	var r33 = rotation_matrix[2][2]

	var theta1 = atan(-r23 / r33)
	var theta2 = atan(r13 * cos(theta1) / r33)
	var theta3 = atan(-r12 / r11)

	theta1 = theta1 * 180.0 / PI
	theta2 = theta2 * 180.0 / PI
	theta3 = theta3 * 180.0 / PI

	return Vector3(theta1, theta2, theta3)


## Find the rotation matrix that rotates a reference vector into a target vector.
static func rotation_matrix_from_vectors(reference: Vector3, target: Vector3) -> Basis:
	# Normalize both vectors
	var a = reference.normalized()
	var b = target.normalized()

	var v = a.cross(b)
	var c = a.dot(b)
	var s = v.length()

	if abs(s) < 1e-6:
		return Basis.IDENTITY

	# Construct rotation matrix
	# See https://stackoverflow.com/questions/45142959/calculate-rotation-matrix-to-align-two-vectors-in-3d-space

	#kmat = np.array([[0, -v[2], v[1]], [v[2], 0, -v[0]], [-v[1], v[0], 0]])
	var kmat = Basis(Vector3(0, v.z, -v.y), Vector3(-v.z, 0, v.x), Vector3(v.y, -v.x, 0))

	#rotation_matrix = np.eye(3) + kmat + kmat.dot(kmat) * ((1 - c) / (s ** 2))
	var rotation_matrix = matadd(
		matadd(Basis.IDENTITY, kmat),
		scalarmul((1 - c) / (s*s), matmul(kmat, kmat))
	)
	return rotation_matrix

static func matadd(a: Basis, b: Basis) -> Basis:
	return Basis(
		a.x + b.x,
		a.y + b.y,
		a.z + b.z
	)

static func matmul(a: Basis, b: Basis) -> Basis:
	return Basis(
		a.xform(b.x),
		a.xform(b.y),
		a.xform(b.z)
	)

static func scalarmul(s: float, a: Basis) -> Basis:
	return Basis(
		s*a.x,
		s*a.y,
		s*a.z
	)

static func transform_to_str(t: Transform) -> String:
	var s = PoolStringArray()
	s.append("")
	for row in range(3):
		var r = ""
		for col in range(4):
			r += "%+.3f" % t[col][row]
			if col < 3:
				r += ", "
		s.append(r)
	return s.join("\n")