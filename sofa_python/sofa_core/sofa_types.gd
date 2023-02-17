extends Reference

enum DOF_DATA_TYPE {
	VEC_1_F,   VEC_1_D,
	VEC_2_F,   VEC_2_D,
	VEC_3_F,   VEC_3_D,
	VEC_6_F,   VEC_6_D,
	RIGID_2_F, RIGID_2_D,
	RIGID_3_F, RIGID_3_D,
}

const DOF_TEMPLATE = {
	"Vec1f": DOF_DATA_TYPE.VEC_1_F,     "Vec1d": DOF_DATA_TYPE.VEC_1_D,
	"Vec2f": DOF_DATA_TYPE.VEC_2_F,     "Vec2d": DOF_DATA_TYPE.VEC_2_D,
	"Vec3f": DOF_DATA_TYPE.VEC_3_F,     "Vec3d": DOF_DATA_TYPE.VEC_3_D,
	"Vec6f": DOF_DATA_TYPE.VEC_6_F,     "Vec6d": DOF_DATA_TYPE.VEC_6_D,
	"Rigid2f": DOF_DATA_TYPE.RIGID_2_F, "Rigid2d": DOF_DATA_TYPE.RIGID_2_D,
	"Rigid3f": DOF_DATA_TYPE.RIGID_3_F, "Rigid3d": DOF_DATA_TYPE.RIGID_3_D
}

const DOF_MAP = {
	DOF_DATA_TYPE.VEC_1_F: "Vec1f",     DOF_DATA_TYPE.VEC_1_D: "Vec1d",
	DOF_DATA_TYPE.VEC_2_F: "Vec2f",     DOF_DATA_TYPE.VEC_2_D: "Vec2d",
	DOF_DATA_TYPE.VEC_3_F: "Vec3f",     DOF_DATA_TYPE.VEC_3_D: "Vec3d",
	DOF_DATA_TYPE.VEC_6_F: "Vec6f",     DOF_DATA_TYPE.VEC_6_D: "Vec6d",
	DOF_DATA_TYPE.RIGID_2_F: "Rigid2f", DOF_DATA_TYPE.RIGID_2_D: "Rigid2d",
	DOF_DATA_TYPE.RIGID_3_F: "Rigid3f", DOF_DATA_TYPE.RIGID_3_D: "Rigid3d"
}

static func dof_template_to_string(dof_template: int) -> String:
	assert(dof_template in DOF_DATA_TYPE.values(), "Unknown DOF_DATA_TYPE")
	return DOF_MAP[dof_template]