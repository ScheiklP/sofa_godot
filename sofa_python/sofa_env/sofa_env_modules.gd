# note: classes are abused as namespaces
class sofa_templates:
	const path = "sofa_env.sofa_templates"


	class camera:
		const path = "sofa_env.sofa_templates.camera"
		const plugin_list = "CAMERA_PLUGIN_LIST"
		const POSE_KWARGS = "POSE_KWARGS"


	class collision:
		const path = "sofa_env.sofa_templates.collision"
		const plugin_list = "COLLISION_PLUGIN_LIST"

		## SOFA names for collision models represented as points, lines, and triangles.
		const CollisionModelType = {
			"POINT":    "CollisionModelType.POINT",
			"LINE":     "CollisionModelType.LINE",
			"TRIANGLE": "CollisionModelType.TRIANGLE",
		}


	class deformable:
		const path = "sofa_env.sofa_templates.deformable"
		const plugin_list = "DEFORMABLE_PLUGIN_LIST"
		const fixture_functions = "FIXTURE_FUNCTIONS"

		## Primitive elements that can be used in a MeshSpringForceField
		const MeshSpringPrimitive = {
			"LINE":     "MeshSpringPrimitive.LINE",
			"TRIANGLE": "MeshSpringPrimitive.TRIANGLE",
			"QUAD":     "MeshSpringPrimitive.QUAD",
			"TETRA":    "MeshSpringPrimitive.TETRA",
			"CUBE":     "MeshSpringPrimitive.CUBE"
		}

	class loader:
		const path = "sofa_env.sofa_templates.loader"
		const plugin_list = "LOADER_PLUGIN_LIST"


	class mappings:
		const path = "sofa_env.sofa_templates.mappings"
		const plugin_list = "MAPPING_PLUGIN_LIST"

		## What mapping is to be used between parent and child topology?
		## E.g. [code]BarycentricMapping[/code] for mapping a mesh to a mesh,
		## [code]RigidMapping[/code] for mapping a mesh to a Rigid3 body (1 pose),
		## [code]IdentityMapping[/code] for mapping two identical meshes.
		const MappingType = {
			"RIGID":       "MappingType.RIGID",
			"BARYCENTRIC": "MappingType.BARYCENTRIC",
			"IDENTITY":    "MappingType.IDENTITY",
		}


	class materials:
		const path = "sofa_env.sofa_templates.materials"
		const plugin_list = "MATERIALS_PLUGIN_LIST"

		## Constitutive models for linear and non-linear elastic materials.
		## Linear and Corotated material describe a linear relationship between strain and stress.
		## [StVenantKirchhoff](https://en.wikipedia.org/wiki/Hyperelastic_material#Saint_Venant%E2%80%93Kirchhoff_model) and 
		## [NeoHookean](https://en.wikipedia.org/wiki/Neo-Hookean_solid) are hyperelastic materials
		## -> non-linear relationship between strain and stress.
		const ConstitutiveModel = {
			"LINEAR":            "ConstitutiveModel.LINEAR",
			"COROTATED":         "ConstitutiveModel.COROTATED",
			"STVENANTKIRCHHOFF": "ConstitutiveModel.STVENANTKIRCHHOFF",
			"NEOHOOKEAN":        "ConstitutiveModel.NEOHOOKEAN",
		}


	class motion_restriction:
		const path = "sofa_env.sofa_templates.motion_restriction"
		const plugin_list = "MOTION_RESTRICTION_PLUGIN_LIST"


	class rigid:
		const path = "sofa_env.sofa_templates.rigid"
		const plugin_list = "RIGID_PLUGIN_LIST"

		## Enum used in ControllableRigidObject to define how motion target and physical body are attached to each other.
		const MechanicalBinding = {
				"ATTACH": "MechanicalBinding.ATTACH",
				"SPRING": "MechanicalBinding.SPRING",
			}


	class scene_header:
		const path = "sofa_env.sofa_templates.scene_header"
		const plugin_list = "SCENE_HEADER_PLUGIN_LIST"

		const VISUAL_STYLES = {
			"full_debug": "VISUAL_STYLES[\"full_debug\"]",
			"debug": "VISUAL_STYLES[\"debug\"]",
			"normal": "VISUAL_STYLES[\"normal\"]",
		}

		## Describes the animation loop of the simulation.
		## For documentation see
		## - [DefaultAnimationLoop](https://www.sofa-framework.org/community/doc/components/animationloops/defaultanimationloop/)
		## - [FreeMotionAnimationLoop](https://www.sofa-framework.org/community/doc/components/animationloops/freemotionanimationloop/) and [more](https://www.sofa-framework.org/community/doc/simulation-principles/constraint/lagrange-constraint/#freemotionanimationloop)
		##
		## TLDR:
		## FreeMotionAnimationLoop includes more steps and components and is results in more realistic simulations.
		## Required for complex constraint-based interactions.
		## DefaultAnimationLoop is easier to set up and runs more stable.
		const AnimationLoopType = {
			"DEFAULT":    "AnimationLoopType.DEFAULT",
			"FREEMOTION": "AnimationLoopType.FREEMOTION",
		}

		static func AugmentedAnimationLoopType() -> Dictionary:
			var loop_type = AnimationLoopType.duplicate(true)
			loop_type["Use Scene Header"] = "use_scene_header"
			return loop_type

		## Describes how collisions are detected. For documentation see
		## - [NewProximityIntersection](https://sofacomponents.readthedocs.io/en/latest/_modules/sofacomponents/CollisionAlgorithm/NewProximityIntersection.html)
		## - [LocalMinDistance](https://www.sofa-framework.org/community/doc/components/collisions/intersectiondetections/localmindistance/)
		## - [MinProximityIntersection](https://www.sofa-framework.org/community/doc/components/collisions/intersectiondetections/minproximityintersection/)
		## - DiscreteIntersection
		## 
		## TLDR:
		## 		MinProximityIntersection is optimized for meshes.
		## 		LocalMinDistance method is similar to MinProximityIntersection but in addition filters the list of DetectionOutput to keep only the contacts with the local minimal distance.
		## 		NewProximityIntersection seems to be an improved method, but there is no documentation.
		## 		DiscreteIntersection does not take arguments for alarmDistance and contactDistance.
		const IntersectionMethod = {
			"NEWPROXIMITY": "IntersectionMethod.NEWPROXIMITY",
			"LOCALMIN":     "IntersectionMethod.LOCALMIN",
			"MINPROXIMITY": "IntersectionMethod.MINPROXIMITY",
			"DISCRETE":     "IntersectionMethod.DISCRETE",
		}

		const ContactManagerResponse = {
			"DEFAULT":  "ContactManagerResponse.DEFAULT",
			"FRICTION": "ContactManagerResponse.FRICTION",
		}

		## Describes the solver used to solve for constraints in the FreeAnimationLoop.
		## From the [documentation](https://www.sofa-framework.org/community/doc/simulation-principles/constraint/lagrange-constraint/#constraintsolver-in-sofa):
		##
		## Two different ConstraintSolver implementations exist in SOFA:
		##		- LCPConstraintSolver: this solvers targets on collision constraints, contacts with frictions which corresponds to unilateral constraints
		##		- GenericConstraintSolver: this solver handles all kind of constraints, i.e. works with any constraint resolution algorithm
		##
		## Moreover, you may find the class ConstraintSolver.
		## This class does not implement a real solver but actually just browses the graph in order to find and use one of the two implementations mentioned above.
		const ConstraintSolverType = {
			"AUTOMATIC": "ConstraintSolverType.AUTOMATIC",
			"GENERIC":   "ConstraintSolverType.GENERIC",
			"LCP":       "ConstraintSolverType.LCP",
		}


	class solver:
		const path = "sofa_env.sofa_templates.solver"
		const plugin_list = "SOLVER_PLUGIN_LIST"

		## Describes the numerical method to find the approximate solution for ordinary differential equations.
		const OdeSolverType = {
			"EXPLICITEULER": "OdeSolverType.EXPLICITEULER",
			"IMPLICITEULER": "OdeSolverType.IMPLICITEULER",
		}

		## Describes the numerical methods that solves the matrix system Ax=b that is built by the OdeSolver.
		const LinearSolverType = {
			"CG":             "LinearSolverType.CG",
			"SPARSELDL":      "LinearSolverType.SPARSELDL",
			"ASYNCSPARSELDL": "LinearSolverType.ASYNCSPARSELDL",
			"BTD":            "LinearSolverType.BTD",
		}

		## SOFA names of the different types of constraint correction.
		## Notes:
		##	UNCOUPLED is recommended for rigid objects.
		##	PRECOMPUTED is recommended for deformable objects. This will create a file on the first creation of the scene. Computation may take a few minutes.
		##	LINEAR is the most accurate but also computationally expensive.
		##	GENERIC is similar to LINEAR, but computes a global Matrix instead of a local per object matrix.
		##
		## Warning:
		## LINEAR and GENERIC require the objects to have DIRECT linear solvers.
		const ConstraintCorrectionType = {
			"UNCOUPLED":   "ConstraintCorrectionType.UNCOUPLED",
			"LINEAR":      "ConstraintCorrectionType.LINEAR",
			"PRECOMPUTED": "ConstraintCorrectionType.PRECOMPUTED",
			"GENERIC":     "ConstraintCorrectionType.GENERIC",
		}


	class topology:
		const path = "sofa_env.sofa_templates.topology"
		const plugin_list = "TOPOLOGY_PLUGIN_LIST"

		const TopologyTypes = {
			"TETRA": "TopologyTypes.TETRA",
			"HEXA":  "TopologyTypes.HEXA",
		}


	class visual:
		const path = "sofa_env.sofa_templates.visual"
		const plugin_list = "VISUAL_PLUGIN_LIST"

