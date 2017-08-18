module mmtruncatedmfreem1
using FinEtools
using FinEtools.AlgoDeforLinearModule
using Base.Test
function test()
    # println("""
    # Vibration modes of truncated cylindrical shell.
    # """)

    # t0 = time()

    E = 205000*phun("MPa");# Young's modulus
    nu = 0.3;# Poisson ratio
    rho = 7850*phun("KG*M^-3");# mass density
    OmegaShift = (2*pi*100) ^ 2; # to resolve rigid body modes
    h = 0.05*phun("M");
    l = 10*h;
    Rmed = h/0.2;
    psi   = 0;    # Cylinder
    nh = 5; nl  = 12; nc = 40;
    tolerance = h/nh/100;
    neigvs = 20;

    MR = DeforModelRed3D
    fens,fes  = H8block(h,l,2*pi,nh,nl,nc)
    # Shape into a cylinder
    R = zeros(3, 3)
    for i = 1:count(fens)
        x, y, z = fens.xyz[i,:];
        rotmat3!(R, [0, z, 0])
        Q = [cos(psi*pi/180) sin(psi*pi/180) 0;
            -sin(psi*pi/180) cos(psi*pi/180) 0;
            0 0 1]
        fens.xyz[i,:] = reshape([x+Rmed-h/2, y-l/2, 0], 1, 3)*Q*R;
    end
    candidates = selectnode(fens, plane = [0.0 0.0 1.0 0.0], thickness = h/1000)
    fens,fes = mergenodes(fens, fes,  tolerance, candidates);

    geom = NodalField(fens.xyz)
    u = NodalField(zeros(size(fens.xyz,1),3)) # displacement field

    numberdofs!(u)

    material=MatDeforElastIso(MR, rho, E, nu, 0.0)

    femm = FEMMDeforLinearMSH8(MR, GeoD(fes, GaussRule(3,2)), material)
    femm = associategeometry!(femm, geom)
    K =stiffness(femm, geom, u)
    femm = FEMMDeforLinear(MR, GeoD(fes, GaussRule(3,3)), material)
    M =mass(femm, geom, u)


    # eigs returns the nev requested eigenvalues in d, the corresponding Ritz vectors
    # v (only if ritzvec=true), the number of converged eigenvalues nconv, the number
    # of iterations niter and the number of matrix vector multiplications nmult, as
    # well as the final residual vector resid.

    if true
        d,v,nev,nconv = eigs(K+OmegaShift*M, M; nev=neigvs, which=:SM)
        d = d - OmegaShift;
        fs = real(sqrt.(complex(d)))/(2*pi)
        # println("Eigenvalues: $fs [Hz]")
        @test norm(sort(fs)[1:8] - [0.0, 0.0, 0.0, 0.0, 0.000166835, 0.000182134, 517.147, 517.147]) < 2.0e-2
        # mode = 7
        # scattersysvec!(u, v[:,mode])
        # File =  "unit_cube_modes.vtk"
        # vtkexportmesh(File, fens, fes; vectors=[("mode$mode", u.values)])
        # @async run(`"paraview.exe" $File`)
    end

    if true
        solver = AlgoDeforLinearModule.gepbinvpwr2
        v0 = eye(size(K,1), 2*neigvs)
        tol = 1.0e-2
        maxiter = 20
        lamb, v, nconv, niter, nmult, lamberr =
            solver(K+OmegaShift*M, M; nev=neigvs, v0=v0, tol=tol, maxiter=maxiter)
        @test nconv != neigvs
        # if nconv < neigvs
            # println("NOT converged")
        # end
        lamb = lamb - OmegaShift;
        fs = real(sqrt.(complex(lamb)))/(2*pi)
        # println("Eigenvalues: $fs [Hz]")
        # println("$(sort(fs))")
        @test norm(sort(fs)[1:8] - [0.0, 0.0, 0.0, 0.0, 7.9048e-5, 0.0, 517.147, 517.147]) < 2.0e-2
        # println("Eigenvalue errors: $lamberr [ND]")
        # mode = 7
        # scattersysvec!(u, v[:,mode])
        # File =  "unit_cube_modes.vtk"
        # vtkexportmesh(File, fens, fes; vectors=[("mode$mode", u.values)])
        # @async run(`"paraview.exe" $File`)
    end

end
end
using mmtruncatedmfreem1
mmtruncatedmfreem1.test()
