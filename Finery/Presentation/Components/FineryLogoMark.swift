import SwiftUI

// MARK: - Cream petal (upper, ivory)

struct FineryLogoCreamPetal: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ nx: Double, _ ny: Double) -> CGPoint {
            CGPoint(x: nx * rect.width, y: ny * rect.height)
        }
        var path = Path()
        path.move(to: p(0.748006, 0.262520))
        path.addCurve(to: p(0.740510, 0.289155), control1: p(0.748006, 0.264434), control2: p(0.743939, 0.278708))
        path.addCurve(to: p(0.707097, 0.356061), control1: p(0.732695, 0.312440), control2: p(0.719617, 0.338756))
        path.addCurve(to: p(0.585726, 0.437640), control1: p(0.676874, 0.398006), control2: p(0.635805, 0.425598))
        path.addCurve(to: p(0.532695, 0.443381), control1: p(0.568421, 0.441866), control2: p(0.561324, 0.442584))
        path.addCurve(to: p(0.465470, 0.450080), control1: p(0.499442, 0.444338), control2: p(0.485805, 0.445694))
        path.addCurve(to: p(0.344338, 0.519856), control1: p(0.417943, 0.460447), control2: p(0.373365, 0.486045))
        path.addCurve(to: p(0.337321, 0.527911), control1: p(0.340670, 0.524083), control2: p(0.337560, 0.527671))
        path.addCurve(to: p(0.327512, 0.541627), control1: p(0.336683, 0.528469), control2: p(0.331818, 0.535327))
        path.addCurve(to: p(0.312679, 0.566587), control1: p(0.323844, 0.547049), control2: p(0.315789, 0.560606))
        path.addLine(to: p(0.311085, 0.569777))
        path.addLine(to: p(0.311085, 0.508772))
        path.addCurve(to: p(0.314593, 0.426236), control1: p(0.311005, 0.445056), control2: p(0.311164, 0.441866))
        path.addCurve(to: p(0.350638, 0.349761), control1: p(0.320494, 0.400000), control2: p(0.333094, 0.373126))
        path.addCurve(to: p(0.391547, 0.309250), control1: p(0.358772, 0.338995), control2: p(0.380064, 0.317863))
        path.addCurve(to: p(0.516587, 0.262440), control1: p(0.427990, 0.282057), control2: p(0.472887, 0.265231))
        path.addCurve(to: p(0.637400, 0.261643), control1: p(0.522169, 0.262121), control2: p(0.576475, 0.261722))
        path.addCurve(to: p(0.748006, 0.262520), control1: p(0.725758, 0.261563), control2: p(0.748006, 0.261722))
        path.closeSubpath()
        return path
    }
}

// MARK: - Gold petal (lower, warm gold)

struct FineryLogoGoldPetal: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ nx: Double, _ ny: Double) -> CGPoint {
            CGPoint(x: nx * rect.width, y: ny * rect.height)
        }
        var path = Path()
        path.move(to: p(0.561643, 0.494418))
        path.addCurve(to: p(0.620175, 0.495774), control1: p(0.615391, 0.494418), control2: p(0.619697, 0.494498))
        path.addCurve(to: p(0.619777, 0.497448), control1: p(0.620494, 0.496491), control2: p(0.620335, 0.497209))
        path.addCurve(to: p(0.619298, 0.498644), control1: p(0.619298, 0.497608), control2: p(0.619059, 0.498166))
        path.addCurve(to: p(0.617943, 0.505981), control1: p(0.619458, 0.499203), control2: p(0.618900, 0.502472))
        path.addCurve(to: p(0.615470, 0.515710), control1: p(0.617065, 0.509490), control2: p(0.615949, 0.513876))
        path.addCurve(to: p(0.613876, 0.519139), control1: p(0.615072, 0.517624), control2: p(0.614354, 0.519139))
        path.addCurve(to: p(0.613557, 0.520335), control1: p(0.613397, 0.519139), control2: p(0.613238, 0.519697))
        path.addCurve(to: p(0.612759, 0.522727), control1: p(0.613796, 0.520973), control2: p(0.613397, 0.522010))
        path.addCurve(to: p(0.612041, 0.524641), control1: p(0.612121, 0.523365), control2: p(0.611722, 0.524242))
        path.addCurve(to: p(0.608931, 0.532855), control1: p(0.612600, 0.525598), control2: p(0.610128, 0.532057))
        path.addCurve(to: p(0.608293, 0.533892), control1: p(0.608453, 0.533174), control2: p(0.608134, 0.533652))
        path.addCurve(to: p(0.607576, 0.536204), control1: p(0.608852, 0.535088), control2: p(0.608373, 0.536683))
        path.addCurve(to: p(0.607018, 0.536762), control1: p(0.607018, 0.535885), control2: p(0.606778, 0.536124))
        path.addCurve(to: p(0.605662, 0.541467), control1: p(0.607257, 0.537400), control2: p(0.606619, 0.539474))
        path.addCurve(to: p(0.601196, 0.550239), control1: p(0.604625, 0.543461), control2: p(0.602632, 0.547368))
        path.addCurve(to: p(0.596730, 0.557257), control1: p(0.599761, 0.553110), control2: p(0.597767, 0.556220))
        path.addCurve(to: p(0.595295, 0.559809), control1: p(0.595694, 0.558214), control2: p(0.595056, 0.559410))
        path.addCurve(to: p(0.594976, 0.560606), control1: p(0.595534, 0.560287), control2: p(0.595375, 0.560606))
        path.addCurve(to: p(0.594258, 0.561164), control1: p(0.594498, 0.560606), control2: p(0.594179, 0.560845))
        path.addCurve(to: p(0.590909, 0.566986), control1: p(0.594498, 0.562201), control2: p(0.591707, 0.566986))
        path.addCurve(to: p(0.590112, 0.568182), control1: p(0.590431, 0.566986), control2: p(0.590112, 0.567544))
        path.addCurve(to: p(0.588995, 0.569936), control1: p(0.590112, 0.568740), control2: p(0.589633, 0.569617))
        path.addCurve(to: p(0.586603, 0.573206), control1: p(0.588437, 0.570255), control2: p(0.587321, 0.571770))
        path.addCurve(to: p(0.584450, 0.575359), control1: p(0.585885, 0.574641), control2: p(0.584928, 0.575598))
        path.addCurve(to: p(0.583892, 0.575518), control1: p(0.584051, 0.575040), control2: p(0.583812, 0.575120))
        path.addCurve(to: p(0.581180, 0.579187), control1: p(0.584051, 0.575917), control2: p(0.582775, 0.577512))
        path.addCurve(to: p(0.578628, 0.582137), control1: p(0.579506, 0.580781), control2: p(0.578389, 0.582137))
        path.addCurve(to: p(0.576236, 0.584928), control1: p(0.578868, 0.582137), control2: p(0.577831, 0.583413))
        path.addCurve(to: p(0.573365, 0.588517), control1: p(0.574641, 0.586443), control2: p(0.573365, 0.588038))
        path.addCurve(to: p(0.572727, 0.589075), control1: p(0.573365, 0.588915), control2: p(0.573046, 0.589234))
        path.addCurve(to: p(0.568740, 0.592185), control1: p(0.572329, 0.588995), control2: p(0.570574, 0.590431))
        path.addCurve(to: p(0.565072, 0.595056), control1: p(0.566986, 0.594019), control2: p(0.565311, 0.595295))
        path.addCurve(to: p(0.564593, 0.595933), control1: p(0.564833, 0.594817), control2: p(0.564593, 0.595215))
        path.addCurve(to: p(0.561244, 0.599442), control1: p(0.564593, 0.596651), control2: p(0.563078, 0.598246))
        path.addCurve(to: p(0.556778, 0.602791), control1: p(0.559330, 0.600558), control2: p(0.557337, 0.602073))
        path.addCurve(to: p(0.556220, 0.603030), control1: p(0.556140, 0.603509), control2: p(0.555981, 0.603589))
        path.addCurve(to: p(0.555183, 0.602951), control1: p(0.556699, 0.602153), control2: p(0.556459, 0.602153))
        path.addCurve(to: p(0.553828, 0.604386), control1: p(0.554226, 0.603509), control2: p(0.553668, 0.604147))
        path.addCurve(to: p(0.550638, 0.606858), control1: p(0.554226, 0.604785), control2: p(0.551914, 0.606619))
        path.addCurve(to: p(0.544338, 0.610925), control1: p(0.548884, 0.607177), control2: p(0.543939, 0.610367))
        path.addCurve(to: p(0.541866, 0.612520), control1: p(0.544498, 0.611244), control2: p(0.543381, 0.611962))
        path.addCurve(to: p(0.539075, 0.614274), control1: p(0.540351, 0.613078), control2: p(0.539075, 0.613876))
        path.addCurve(to: p(0.538278, 0.614434), control1: p(0.539075, 0.614593), control2: p(0.538756, 0.614673))
        path.addCurve(to: p(0.537480, 0.614753), control1: p(0.537879, 0.614195), control2: p(0.537480, 0.614274))
        path.addCurve(to: p(0.532775, 0.616507), control1: p(0.537480, 0.615630), control2: p(0.534370, 0.616826))
        path.addCurve(to: p(0.532217, 0.617065), control1: p(0.532217, 0.616427), control2: p(0.531978, 0.616667))
        path.addCurve(to: p(0.526954, 0.619777), control1: p(0.532695, 0.617783), control2: p(0.528070, 0.620175))
        path.addCurve(to: p(0.526316, 0.620415), control1: p(0.526555, 0.619697), control2: p(0.526316, 0.620016))
        path.addCurve(to: p(0.525359, 0.621132), control1: p(0.526316, 0.620893), control2: p(0.525837, 0.621212))
        path.addCurve(to: p(0.520574, 0.622249), control1: p(0.523206, 0.620893), control2: p(0.521611, 0.621292))
        path.addCurve(to: p(0.513955, 0.625199), control1: p(0.518820, 0.624003), control2: p(0.516188, 0.625199))
        path.addCurve(to: p(0.510128, 0.626316), control1: p(0.512839, 0.625199), control2: p(0.511085, 0.625678))
        path.addCurve(to: p(0.505183, 0.627911), control1: p(0.509171, 0.626954), control2: p(0.506938, 0.627671))
        path.addCurve(to: p(0.497209, 0.629984), control1: p(0.501435, 0.628549), control2: p(0.499362, 0.629027))
        path.addCurve(to: p(0.474721, 0.634290), control1: p(0.494896, 0.631021), control2: p(0.479187, 0.633971))
        path.addCurve(to: p(0.472408, 0.634928), control1: p(0.473764, 0.634290), control2: p(0.472727, 0.634609))
        path.addCurve(to: p(0.469537, 0.635566), control1: p(0.472089, 0.635327), control2: p(0.470813, 0.635566))
        path.addCurve(to: p(0.467305, 0.636364), control1: p(0.468341, 0.635566), control2: p(0.467305, 0.635885))
        path.addCurve(to: p(0.464354, 0.637560), control1: p(0.467305, 0.636762), control2: p(0.465949, 0.637321))
        path.addCurve(to: p(0.459729, 0.638836), control1: p(0.462679, 0.637879), control2: p(0.460606, 0.638437))
        path.addCurve(to: p(0.442424, 0.645136), control1: p(0.455263, 0.640909), control2: p(0.443620, 0.645136))
        path.addCurve(to: p(0.440989, 0.645853), control1: p(0.441627, 0.645136), control2: p(0.440989, 0.645455))
        path.addCurve(to: p(0.436124, 0.647927), control1: p(0.440989, 0.646651), control2: p(0.439394, 0.647289))
        path.addCurve(to: p(0.433652, 0.649522), control1: p(0.435088, 0.648166), control2: p(0.433971, 0.648804))
        path.addCurve(to: p(0.431419, 0.650718), control1: p(0.433254, 0.650159), control2: p(0.432297, 0.650718))
        path.addCurve(to: p(0.428788, 0.651914), control1: p(0.430622, 0.650718), control2: p(0.429426, 0.651276))
        path.addCurve(to: p(0.427113, 0.652552), control1: p(0.428150, 0.652552), control2: p(0.427432, 0.652791))
        path.addCurve(to: p(0.426635, 0.653030), control1: p(0.426874, 0.652233), control2: p(0.426635, 0.652472))
        path.addCurve(to: p(0.425837, 0.653509), control1: p(0.426635, 0.653589), control2: p(0.426316, 0.653748))
        path.addCurve(to: p(0.425040, 0.653828), control1: p(0.425439, 0.653270), control2: p(0.425040, 0.653349))
        path.addCurve(to: p(0.419617, 0.657018), control1: p(0.425040, 0.654705), control2: p(0.420016, 0.657576))
        path.addCurve(to: p(0.418660, 0.657815), control1: p(0.419537, 0.656858), control2: p(0.419059, 0.657177))
        path.addCurve(to: p(0.416667, 0.659171), control1: p(0.418341, 0.658453), control2: p(0.417384, 0.659091))
        path.addCurve(to: p(0.413477, 0.661404), control1: p(0.415949, 0.659250), control2: p(0.414514, 0.660287))
        path.addCurve(to: p(0.410686, 0.663477), control1: p(0.412440, 0.662520), control2: p(0.411164, 0.663477))
        path.addCurve(to: p(0.407337, 0.665869), control1: p(0.410207, 0.663477), control2: p(0.408692, 0.664514))
        path.addCurve(to: p(0.403907, 0.668262), control1: p(0.406061, 0.667145), control2: p(0.404466, 0.668262))
        path.addCurve(to: p(0.401595, 0.670016), control1: p(0.403270, 0.668262), control2: p(0.402233, 0.669059))
        path.addCurve(to: p(0.400319, 0.671053), control1: p(0.400877, 0.670973), control2: p(0.400319, 0.671451))
        path.addCurve(to: p(0.397448, 0.673445), control1: p(0.400319, 0.670574), control2: p(0.399043, 0.671691))
        path.addCurve(to: p(0.393700, 0.676635), control1: p(0.395933, 0.675199), control2: p(0.394258, 0.676635))
        path.addCurve(to: p(0.391786, 0.678628), control1: p(0.393222, 0.676635), control2: p(0.392344, 0.677512))
        path.addCurve(to: p(0.390191, 0.680622), control1: p(0.391228, 0.679745), control2: p(0.390510, 0.680622))
        path.addCurve(to: p(0.389713, 0.681180), control1: p(0.389872, 0.680622), control2: p(0.389633, 0.680861))
        path.addCurve(to: p(0.388118, 0.682695), control1: p(0.389872, 0.681499), control2: p(0.389155, 0.682217))
        path.addCurve(to: p(0.383174, 0.687480), control1: p(0.385566, 0.684051), control2: p(0.382775, 0.686762))
        path.addCurve(to: p(0.381021, 0.689394), control1: p(0.383573, 0.688118), control2: p(0.382137, 0.689394))
        path.addCurve(to: p(0.380223, 0.690191), control1: p(0.380622, 0.689394), control2: p(0.380303, 0.689713))
        path.addCurve(to: p(0.379187, 0.691786), control1: p(0.380223, 0.690590), control2: p(0.379665, 0.691308))
        path.addCurve(to: p(0.373206, 0.699043), control1: p(0.377113, 0.693461), control2: p(0.372089, 0.699601))
        path.addCurve(to: p(0.372249, 0.700319), control1: p(0.373844, 0.698724), control2: p(0.373445, 0.699282))
        path.addCurve(to: p(0.370016, 0.703429), control1: p(0.370973, 0.701356), control2: p(0.370016, 0.702791))
        path.addCurve(to: p(0.367624, 0.706539), control1: p(0.370016, 0.704147), control2: p(0.368979, 0.705502))
        path.addCurve(to: p(0.365630, 0.708931), control1: p(0.366348, 0.707496), control2: p(0.365470, 0.708612))
        path.addCurve(to: p(0.364753, 0.710048), control1: p(0.365869, 0.709250), control2: p(0.365470, 0.709809))
        path.addCurve(to: p(0.362759, 0.712919), control1: p(0.364115, 0.710287), control2: p(0.363158, 0.711563))
        path.addCurve(to: p(0.361164, 0.715311), control1: p(0.362281, 0.714195), control2: p(0.361563, 0.715311))
        path.addCurve(to: p(0.360447, 0.716268), control1: p(0.360766, 0.715311), control2: p(0.360447, 0.715710))
        path.addCurve(to: p(0.355263, 0.722568), control1: p(0.360447, 0.717225), control2: p(0.359410, 0.718421))
        path.addCurve(to: p(0.353668, 0.724880), control1: p(0.353987, 0.723844), control2: p(0.353270, 0.724880))
        path.addCurve(to: p(0.352791, 0.726156), control1: p(0.354067, 0.724880), control2: p(0.353668, 0.725439))
        path.addCurve(to: p(0.352472, 0.726874), control1: p(0.351994, 0.726794), control2: p(0.351834, 0.727193))
        path.addCurve(to: p(0.351754, 0.727990), control1: p(0.353110, 0.726555), control2: p(0.352791, 0.727113))
        path.addCurve(to: p(0.350558, 0.729665), control1: p(0.350718, 0.728947), control2: p(0.350239, 0.729665))
        path.addCurve(to: p(0.350000, 0.730702), control1: p(0.350957, 0.729665), control2: p(0.350718, 0.730144))
        path.addCurve(to: p(0.348246, 0.733094), control1: p(0.349362, 0.731260), control2: p(0.348565, 0.732297))
        path.addCurve(to: p(0.346810, 0.733971), control1: p(0.347927, 0.733971), control2: p(0.347289, 0.734290))
        path.addCurve(to: p(0.346411, 0.734370), control1: p(0.346172, 0.733652), control2: p(0.346093, 0.733732))
        path.addCurve(to: p(0.345774, 0.735726), control1: p(0.346730, 0.734848), control2: p(0.346411, 0.735486))
        path.addCurve(to: p(0.344498, 0.737241), control1: p(0.345056, 0.735965), control2: p(0.344498, 0.736683))
        path.addCurve(to: p(0.342026, 0.740750), control1: p(0.344498, 0.737879), control2: p(0.343381, 0.739394))
        path.addCurve(to: p(0.340112, 0.743222), control1: p(0.340670, 0.742105), control2: p(0.339793, 0.743222))
        path.addCurve(to: p(0.337560, 0.746491), control1: p(0.340351, 0.743222), control2: p(0.339234, 0.744737))
        path.addCurve(to: p(0.334689, 0.750478), control1: p(0.335885, 0.748325), control2: p(0.334609, 0.750080))
        path.addCurve(to: p(0.333333, 0.751994), control1: p(0.334848, 0.750877), control2: p(0.334211, 0.751515))
        path.addCurve(to: p(0.331738, 0.753987), control1: p(0.332456, 0.752472), control2: p(0.331738, 0.753349))
        path.addCurve(to: p(0.330861, 0.755183), control1: p(0.331738, 0.754625), control2: p(0.331340, 0.755183))
        path.addCurve(to: p(0.330463, 0.755821), control1: p(0.330463, 0.755183), control2: p(0.330223, 0.755502))
        path.addCurve(to: p(0.328469, 0.758293), control1: p(0.330702, 0.756220), control2: p(0.329825, 0.757337))
        path.addCurve(to: p(0.326475, 0.760526), control1: p(0.327113, 0.759330), control2: p(0.326236, 0.760287))
        path.addCurve(to: p(0.321372, 0.765949), control1: p(0.327193, 0.761324), control2: p(0.322329, 0.766587))
        path.addCurve(to: p(0.320175, 0.766268), control1: p(0.320973, 0.765710), control2: p(0.320494, 0.765869))
        path.addCurve(to: p(0.321531, 0.766746), control1: p(0.319936, 0.766746), control2: p(0.320494, 0.766906))
        path.addCurve(to: p(0.321212, 0.768341), control1: p(0.323285, 0.766427), control2: p(0.323285, 0.766507))
        path.addCurve(to: p(0.318979, 0.771053), control1: p(0.319936, 0.769378), control2: p(0.318979, 0.770654))
        path.addCurve(to: p(0.316029, 0.774880), control1: p(0.318979, 0.771531), control2: p(0.317624, 0.773206))
        path.addCurve(to: p(0.314195, 0.777193), control1: p(0.314354, 0.776475), control2: p(0.313557, 0.777592))
        path.addCurve(to: p(0.313876, 0.777831), control1: p(0.314833, 0.776874), control2: p(0.314673, 0.777193))
        path.addCurve(to: p(0.311802, 0.778309), control1: p(0.312919, 0.778628), control2: p(0.312121, 0.778788))
        path.addCurve(to: p(0.311643, 0.716746), control1: p(0.311563, 0.777911), control2: p(0.311483, 0.750159))
        path.addCurve(to: p(0.311882, 0.653270), control1: p(0.311802, 0.683254), control2: p(0.311962, 0.654705))
        path.addCurve(to: p(0.312520, 0.650718), control1: p(0.311882, 0.651914), control2: p(0.312201, 0.650718))
        path.addCurve(to: p(0.313238, 0.647209), control1: p(0.312839, 0.650718), control2: p(0.313158, 0.649123))
        path.addCurve(to: p(0.313876, 0.642584), control1: p(0.313238, 0.645215), control2: p(0.313557, 0.643142))
        path.addCurve(to: p(0.314354, 0.640191), control1: p(0.314274, 0.642026), control2: p(0.314434, 0.640989))
        path.addCurve(to: p(0.314992, 0.638357), control1: p(0.314195, 0.639474), control2: p(0.314514, 0.638676))
        path.addCurve(to: p(0.315789, 0.635646), control1: p(0.315391, 0.638118), control2: p(0.315789, 0.636842))
        path.addCurve(to: p(0.316348, 0.632855), control1: p(0.315789, 0.634450), control2: p(0.316029, 0.633174))
        path.addCurve(to: p(0.316986, 0.631738), control1: p(0.316746, 0.632536), control2: p(0.316986, 0.631978))
        path.addCurve(to: p(0.319059, 0.625199), control1: p(0.317225, 0.629107), control2: p(0.318421, 0.625199))
        path.addCurve(to: p(0.319378, 0.624402), control1: p(0.319537, 0.625199), control2: p(0.319617, 0.624801))
        path.addCurve(to: p(0.319777, 0.623604), control1: p(0.319139, 0.623923), control2: p(0.319298, 0.623604))
        path.addCurve(to: p(0.320415, 0.622568), control1: p(0.320255, 0.623604), control2: p(0.320574, 0.623126))
        path.addCurve(to: p(0.330064, 0.599681), control1: p(0.320016, 0.620734), control2: p(0.328309, 0.601037))
        path.addCurve(to: p(0.332057, 0.595853), control1: p(0.330383, 0.599442), control2: p(0.331260, 0.597767))
        path.addCurve(to: p(0.334211, 0.592504), control1: p(0.332935, 0.594019), control2: p(0.333892, 0.592504))
        path.addCurve(to: p(0.335726, 0.589633), control1: p(0.334530, 0.592504), control2: p(0.335247, 0.591228))
        path.addCurve(to: p(0.337799, 0.586364), control1: p(0.336284, 0.588118), control2: p(0.337161, 0.586603))
        path.addCurve(to: p(0.338915, 0.585167), control1: p(0.338437, 0.586124), control2: p(0.338915, 0.585566))
        path.addCurve(to: p(0.340351, 0.583174), control1: p(0.338915, 0.584689), control2: p(0.339553, 0.583812))
        path.addCurve(to: p(0.340510, 0.582536), control1: p(0.341228, 0.582376), control2: p(0.341308, 0.582217))
        path.addCurve(to: p(0.340590, 0.581978), control1: p(0.339553, 0.582935), control2: p(0.339553, 0.582855))
        path.addCurve(to: p(0.342344, 0.579506), control1: p(0.341228, 0.581419), control2: p(0.342026, 0.580303))
        path.addCurve(to: p(0.343700, 0.578150), control1: p(0.342584, 0.578788), control2: p(0.343222, 0.578150))
        path.addCurve(to: p(0.344498, 0.576954), control1: p(0.344099, 0.578150), control2: p(0.344498, 0.577592))
        path.addCurve(to: p(0.346890, 0.573684), control1: p(0.344498, 0.576316), control2: p(0.345534, 0.574801))
        path.addCurve(to: p(0.348884, 0.570973), control1: p(0.348166, 0.572488), control2: p(0.349043, 0.571292))
        path.addCurve(to: p(0.351515, 0.567544), control1: p(0.348724, 0.570654), control2: p(0.349841, 0.569139))
        path.addCurve(to: p(0.356061, 0.562041), control1: p(0.355024, 0.564195), control2: p(0.356459, 0.562520))
        path.addCurve(to: p(0.360048, 0.557895), control1: p(0.355901, 0.561882), control2: p(0.357735, 0.560048))
        path.addCurve(to: p(0.363955, 0.553349), control1: p(0.362440, 0.555742), control2: p(0.364195, 0.553748))
        path.addCurve(to: p(0.364593, 0.552632), control1: p(0.363716, 0.552951), control2: p(0.364035, 0.552632))
        path.addCurve(to: p(0.368740, 0.549043), control1: p(0.365152, 0.552632), control2: p(0.366986, 0.550957))
        path.addCurve(to: p(0.372568, 0.545933), control1: p(0.370415, 0.547129), control2: p(0.372169, 0.545694))
        path.addCurve(to: p(0.373046, 0.545295), control1: p(0.372967, 0.546172), control2: p(0.373126, 0.545933))
        path.addCurve(to: p(0.373764, 0.544418), control1: p(0.372887, 0.544737), control2: p(0.373285, 0.544338))
        path.addCurve(to: p(0.374561, 0.544019), control1: p(0.374322, 0.544577), control2: p(0.374721, 0.544338))
        path.addCurve(to: p(0.385167, 0.535247), control1: p(0.374322, 0.543142), control2: p(0.383493, 0.535566))
        path.addCurve(to: p(0.387161, 0.534131), control1: p(0.385805, 0.535088), control2: p(0.386762, 0.534609))
        path.addCurve(to: p(0.386842, 0.533892), control1: p(0.387719, 0.533493), control2: p(0.387640, 0.533493))
        path.addCurve(to: p(0.386284, 0.533652), control1: p(0.386124, 0.534290), control2: p(0.385885, 0.534211))
        path.addCurve(to: p(0.388038, 0.532695), control1: p(0.386603, 0.533094), control2: p(0.387400, 0.532695))
        path.addCurve(to: p(0.389155, 0.531898), control1: p(0.388676, 0.532695), control2: p(0.389155, 0.532376))
        path.addCurve(to: p(0.390510, 0.531659), control1: p(0.389155, 0.531499), control2: p(0.389713, 0.531419))
        path.addCurve(to: p(0.391308, 0.531260), control1: p(0.391308, 0.531978), control2: p(0.391627, 0.531818))
        path.addCurve(to: p(0.395853, 0.527671), control1: p(0.390670, 0.530303), control2: p(0.395056, 0.526874))
        path.addCurve(to: p(0.396332, 0.527193), control1: p(0.396093, 0.527911), control2: p(0.396332, 0.527751))
        path.addCurve(to: p(0.397129, 0.526715), control1: p(0.396332, 0.526635), control2: p(0.396730, 0.526475))
        path.addCurve(to: p(0.398405, 0.525917), control1: p(0.397608, 0.526954), control2: p(0.398166, 0.526635))
        path.addCurve(to: p(0.404545, 0.522169), control1: p(0.398963, 0.524641), control2: p(0.403429, 0.521850))
        path.addCurve(to: p(0.405104, 0.521611), control1: p(0.404864, 0.522249), control2: p(0.405104, 0.522010))
        path.addCurve(to: p(0.419856, 0.513557), control1: p(0.405104, 0.520734), control2: p(0.418182, 0.513557))
        path.addCurve(to: p(0.421053, 0.512839), control1: p(0.420494, 0.513557), control2: p(0.421053, 0.513238))
        path.addCurve(to: p(0.429585, 0.509330), control1: p(0.421053, 0.512121), control2: p(0.427831, 0.509330))
        path.addCurve(to: p(0.430622, 0.508692), control1: p(0.430144, 0.509330), control2: p(0.430622, 0.509011))
        path.addCurve(to: p(0.431818, 0.508453), control1: p(0.430622, 0.508293), control2: p(0.431180, 0.508214))
        path.addCurve(to: p(0.433014, 0.508134), control1: p(0.432456, 0.508772), control2: p(0.433014, 0.508533))
        path.addCurve(to: p(0.442663, 0.504386), control1: p(0.433014, 0.507097), control2: p(0.441627, 0.503828))
        path.addCurve(to: p(0.443381, 0.504067), control1: p(0.443062, 0.504705), control2: p(0.443381, 0.504545))
        path.addCurve(to: p(0.449362, 0.501914), control1: p(0.443381, 0.503429), control2: p(0.446093, 0.502472))
        path.addCurve(to: p(0.450797, 0.501595), control1: p(0.449841, 0.501834), control2: p(0.450399, 0.501675))
        path.addCurve(to: p(0.451994, 0.501196), control1: p(0.451116, 0.501515), control2: p(0.451595, 0.501356))
        path.addCurve(to: p(0.453828, 0.500478), control1: p(0.452313, 0.501116), control2: p(0.453110, 0.500797))
        path.addCurve(to: p(0.457018, 0.499681), control1: p(0.454545, 0.500159), control2: p(0.455981, 0.499841))
        path.addCurve(to: p(0.460367, 0.498804), control1: p(0.458054, 0.499522), control2: p(0.459569, 0.499123))
        path.addCurve(to: p(0.462281, 0.498724), control1: p(0.461164, 0.498485), control2: p(0.462041, 0.498405))
        path.addCurve(to: p(0.463716, 0.498405), control1: p(0.462520, 0.498963), control2: p(0.463238, 0.498804))
        path.addCurve(to: p(0.467783, 0.497448), control1: p(0.464274, 0.497927), control2: p(0.466108, 0.497528))
        path.addCurve(to: p(0.471850, 0.496651), control1: p(0.469537, 0.497448), control2: p(0.471292, 0.497049))
        path.addCurve(to: p(0.473844, 0.496093), control1: p(0.472329, 0.496252), control2: p(0.473206, 0.496013))
        path.addCurve(to: p(0.477113, 0.495614), control1: p(0.474402, 0.496172), control2: p(0.475917, 0.496013))
        path.addCurve(to: p(0.497608, 0.494099), control1: p(0.480941, 0.494577), control2: p(0.491308, 0.493780))
        path.addCurve(to: p(0.561643, 0.494418), control1: p(0.500877, 0.494179), control2: p(0.529745, 0.494338))
        path.closeSubpath()
        return path
    }
}

// MARK: - Combined mark

struct FineryLogoMark: View {
    var body: some View {
        ZStack {
            FineryLogoGoldPetal()
                .fill(Color(red: 0.808, green: 0.647, blue: 0.427)) // #CDA46D
            FineryLogoCreamPetal()
                .fill(Color(red: 0.949, green: 0.918, blue: 0.875)) // #F2EADE
        }
    }
}

// MARK: - Fitted mark (crops to logo bounding box, fills any frame)
// Logo occupies [0.311..0.748] × [0.262..0.779] of the 0..1 normalized space.
// This view expands the drawing canvas so only the logo region is visible.

struct FineryLogoMarkFitted: View {
    private static let bx: CGFloat = 0.311
    private static let by: CGFloat = 0.262
    private static let bw: CGFloat = 0.437   // 0.748 - 0.311
    private static let bh: CGFloat = 0.517   // 0.779 - 0.262

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let canvasW = w / Self.bw
            let canvasH = h / Self.bh
            ZStack {
                FineryLogoGoldPetal()
                    .fill(Color(red: 0.808, green: 0.647, blue: 0.427))
                FineryLogoCreamPetal()
                    .fill(Color(red: 0.949, green: 0.918, blue: 0.875))
            }
            .frame(width: canvasW, height: canvasH)
            .offset(x: -Self.bx * canvasW, y: -Self.by * canvasH)
        }
        .clipped()
    }
}

// MARK: - Preview

#Preview("Finery logo mark") {
    ZStack {
        Color(red: 0.102, green: 0.082, blue: 0.035)
            .ignoresSafeArea()
        FineryLogoMark()
            .frame(width: 280, height: 280)
    }
}

#Preview("Finery logo fitted") {
    ZStack {
        Color(red: 0.102, green: 0.082, blue: 0.035)
            .ignoresSafeArea()
        FineryLogoMarkFitted()
            .frame(width: 120, height: 120)
    }
}
