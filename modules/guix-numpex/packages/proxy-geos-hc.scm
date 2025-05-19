(define-module (guix-numpex_pc5 packages proxy-geos-hc)
  #:use-module (guix)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (guix build-system cmake)
  #:use-module (guix git-download)
  #:use-module (guix-hpc-non-free packages cpp)
  #:use-module (guix-science-nonfree packages cuda) 
  #:use-module (amd packages rocm-hip)
  #:use-module (amd packages rocm-libs)
  #:use-module (guix-numpex_pc5 packages kokkos-raja-models)
  #:use-module (llnl tainted geos)
  #:use-module (llnl geos)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages valgrind)
  #:use-module (gnu packages base)
  #:use-module (gnu packages check)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages code)
  #:use-module (gnu packages sphinx)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages pkg-config))


  ;; proxy-geos-hc: default without any backend model (fd_SEQUENTIAL and sem_SEQUENTIAL executables)
(define-public proxy-geos
  (package
    (name "proxy-geos")
    (version "0.0")
    (source
      (origin
        (method git-fetch)
        (uri (git-reference
              (url "https://gitlab.inria.fr/numpex-pc5/wp2-co-design/proxy-geos-hc.git")
              (commit "ae94419374d7ab08adf95b4488288bc32476a25e")
	      (recursive? #t)))
        (file-name (git-file-name name version))
        (sha256 (base32 "1s80chzp3p2h684s5bnysk6xs5fpdx5kwbl3h4mj99pg5310dhjm"))))
    (native-inputs
      (list gcc-toolchain-11 doxygen clang-toolchain-11 gfortran-toolchain valgrind binutils coreutils-8.30 which cppcheck cmakelang astyle python-sphinx python-yapf uncrustify pkg-config))
    (build-system cmake-build-system)
    (arguments (list #:configure-flags #~(list "-DCMAKE_C_COMPILER=gcc"
                                          "-DCMAKE_CXX_COMPILER=g++"
                                          "-DENABLE_TESTS=OFF")
                     #:tests? #f
                     #:build-type "Release"))
    (home-page "https://gitlab.inria.fr/numpex-pc5/wp2-co-design/proxy-geos-hc")
    (synopsis "proxy-geos-hc a GEOSX inspired mini-app for acoustic wave propagation problem with SEM and FD solvers ")
    (description "The proxy-geos-hc project  collects a suite of simple codes representing real applications. 
It is intended to be a standard tool for evaluating and comparing the performance of different high-performance computing (HPC) systems, particularly those used for scientific simulations. 
Current implementation of the proxyApp includes SEM (Spectral finite Element Methods) and FD (Finite Differences methods) to solve 2nd order acoustic wave equation")
    (license license:gpl1+)))

    ;; proxy-geos with kokkos (the default is serial).  (fd_Kokkos and sem_Kokkos executables)
(define-public proxy-geos-kokkos
  (package
    (inherit proxy-geos)
    (name "proxy-geos-kokkos")
    (arguments
      (substitute-keyword-arguments (package-arguments proxy-geos)
        ((#:configure-flags flags)
        #~(append (list "-DUSE_KOKKOS=ON")
                  #$flags))))
    (inputs
      (modify-inputs (package-inputs proxy-geos)
        (prepend kokkos)))
  ))

;; for proxy-geos with KOKKOS and only openmp enabled, use the following package transformation
;; guix shell -L guix/channel --pure proxy-geos-kokkos --with-configure-flag=proxy-geos-kokkos=-DENABLE_OPENMP=ON --with-configure-flag=kokkos=-DENABLE_OPENMP=ON

  ;; proxy-geos package template with kokkos. cuda toolkit and the corresponding architecture flag to be specified
  ;; ?? refer to cuda-package in kokkos-cuda ?
(define (make-proxy-geos-kokkos-cuda name kokkos-cuda cuda-package mycudaarch)
  (package/inherit proxy-geos-kokkos
  (name name)
  (arguments (substitute-keyword-arguments (package-arguments proxy-geos-kokkos)
                 ((#:configure-flags flags)
                  #~(append (list (string-append "-DCMAKE_CUDA_ARCHITECTURES="#$mycudaarch)
                                  "-DENABLE_CUDA=ON"
                                  (string-append "-DCUDA_TOOLKIT_ROOT_DIR="#$(this-package-input "cuda-toolkit"))
                                  (string-append "-DDEVICE=GPU_SM"#$mycudaarch))
                              #$flags))
                 ;; Cannot run tests due to lack of specific hardware
                 ((#:tests? _ #t)
                  #f)
                 ;; RUNPATH validation fails since libcuda.so.1 is not present at build
                 ;; time.
                 ((#:validate-runpath? #f #f)
                  #f)))
  (inputs (modify-inputs (package-inputs proxy-geos-kokkos)
      (delete "kokkos")
      (append kokkos-cuda)
      (prepend cuda-package)))))

(define-public proxy-geos-kokkos-cuda-k40
  ;; This architecture is not supported by CUDA 12
  (make-proxy-geos-kokkos-cuda "proxy-geos-kokkos-cuda-k40" kokkos-cuda-k40 cuda-11 "35"))

(define-public proxy-geos-kokkos-cuda-a40
  (make-proxy-geos-kokkos-cuda "proxy-geos-kokkos-cuda-a40" kokkos-cuda-a40 cuda "86"))

(define-public proxy-geos-kokkos-cuda-a100
  (make-proxy-geos-kokkos-cuda "proxy-geos-kokkos-cuda-a100" kokkos-cuda-a100 cuda "80"))

(define-public proxy-geos-kokkos-cuda-v100
  (make-proxy-geos-kokkos-cuda "proxy-geos-kokkos-cuda-v100" kokkos-cuda-v100 cuda "70"))

(define-public proxy-geos-kokkos-cuda-p100
  (make-proxy-geos-kokkos-cuda "proxy-geos-kokkos-cuda-p100" kokkos-cuda-p100 cuda "60"))

(define-public proxy-geos-kokkos-cuda-ada
  (make-proxy-geos-kokkos-cuda "proxy-geos-kokkos-cuda-ada" kokkos-cuda-ada cuda "89"))

(define-public proxy-geos-kokkos-cuda-t4
  (make-proxy-geos-kokkos-cuda "proxy-geos-kokkos-cuda-t4" kokkos-cuda-t4 cuda "75"))

;; for proxy-geos using KOKKOS, with both GPU and openMP enable use
;; guix shell -L guix/channel --pure proxy-geos-kokkos-cuda-<arch> --with-configure-flag=proxy-geos-kokkos-cuda-<arch>=-DENABLE_OPENMP=ON --with-configure-flag=kokkos-cuda-<arch>=-DENABLE_OPENMP=ON

(define (make-proxy-geos-kokkos-cuda name kokkos-cuda cuda-package mycudaarch)
  (package/inherit proxy-geos-kokkos
  (name name)
  (arguments (substitute-keyword-arguments (package-arguments proxy-geos-kokkos)
                 ((#:configure-flags flags)
                  #~(append (list (string-append "-DCMAKE_CUDA_ARCHITECTURES="#$mycudaarch)
                                  "-DENABLE_CUDA=ON"
                                  (string-append "-DCUDA_TOOLKIT_ROOT_DIR="#$(this-package-input "cuda-toolkit"))
                                  (string-append "-DDEVICE=GPU_SM"#$mycudaarch))
                              #$flags))
                 ;; Cannot run tests due to lack of specific hardware
                 ((#:tests? _ #t)
                  #f)
                 ;; RUNPATH validation fails since libcuda.so.1 is not present at build
                 ;; time.
                 ((#:validate-runpath? #f #f)
                  #f)))
  (inputs (modify-inputs (package-inputs proxy-geos-kokkos)
      (delete "kokkos")
      (append kokkos-cuda)
      (prepend cuda-package)))))

(define-public proxy-geos-kokkos-cuda-k40
  ;; This architecture is not supported by CUDA 12
  (make-proxy-geos-kokkos-cuda "proxy-geos-kokkos-cuda-k40" kokkos-cuda-k40 cuda-11 "35"))

(define-public proxy-geos-kokkos-cuda-a40
  (make-proxy-geos-kokkos-cuda "proxy-geos-kokkos-cuda-a40" kokkos-cuda-a40 cuda "86"))

(define-public proxy-geos-kokkos-cuda-a100
  (make-proxy-geos-kokkos-cuda "proxy-geos-kokkos-cuda-a100" kokkos-cuda-a100 cuda "80"))

(define-public proxy-geos-kokkos-cuda-v100
  (make-proxy-geos-kokkos-cuda "proxy-geos-kokkos-cuda-v100" kokkos-cuda-v100 cuda "70"))

(define-public proxy-geos-kokkos-cuda-p100
  (make-proxy-geos-kokkos-cuda "proxy-geos-kokkos-cuda-p100" kokkos-cuda-p100 cuda "60"))

(define-public proxy-geos-kokkos-cuda-ada
  (make-proxy-geos-kokkos-cuda "proxy-geos-kokkos-cuda-ada" kokkos-cuda-ada cuda "89"))

(define-public proxy-geos-kokkos-cuda-t4
  (make-proxy-geos-kokkos-cuda "proxy-geos-kokkos-cuda-t4" kokkos-cuda-t4 cuda "75"))
;; proxy-geos with raja .  (fd_raja and sem_raja executables)
;; In the current implementation, we don't consider adiak, caliper for performance analysis.
(define-public proxy-geos-raja
  (package
    (inherit proxy-geos)
    (name "proxy-geos-raja")
    (arguments
      (substitute-keyword-arguments (package-arguments proxy-geos)
        ((#:configure-flags flags)
        #~(append (list "-DUSE_RAJA=ON"
                        "-DENABLE_UMPIRE=ON" ;; Is mandatary.. the findpackage could be hard-coded.
                        "-DENABLE_CHAI=ON" ;; Is mandatary.. the findpackage could be hard-coded.
                        "-DRAJA_ENABLE_VECTORIZATION=OFF"
                        "-DENABLE_OPENMP=ON")
                  #$flags))))
    (inputs
      (modify-inputs (package-inputs proxy-geos)
        (append camp)
        (append raja)
        (append chai)))
  ))

;; proxy-geos using Raja abstraction library with OpenMP and GPU backends supported. Default GPU architecture
(define-public proxy-geos-raja-cuda
  (package
    (inherit proxy-geos)
    (name "proxy-geos-raja-cuda")
    (arguments
      (substitute-keyword-arguments (package-arguments proxy-geos-raja)
        ((#:configure-flags flags)
        #~(append (list "-DENABLE_CUDA=ON"
                        "-DCMAKE_CUDA_FLAGS=--std=c++17 --expt-relaxed-constexpr --expt-extended-lambda"
                        (string-append "-DCUDA_TOOLKIT_ROOT_DIR="#$(this-package-input "cuda-toolkit")))
                  #$flags))))
    (inputs
      (modify-inputs (package-inputs proxy-geos-raja)
        (delete "camp")
        (delete "raja")
        (delete "chai")
        (append camp-cuda)
        (append raja-cuda)
        (append chai-cuda)
        (prepend cuda)))
  ))

(define (make-proxy-geos-raja-cuda-arch name mycudaarch camp-cuda-arch raja-cuda-arch chai-cuda-arch)
  (package/inherit proxy-geos-raja-cuda
  (name name)
  (arguments
    (substitute-keyword-arguments (package-arguments proxy-geos-raja-cuda)
      ((#:configure-flags flags)
        #~(append (list (string-append "-DCMAKE_CUDA_ARCHITECTURES="#$mycudaarch)
                          "-DCUDA_ARCH=sm_"#$mycudaarch ;;Not used
                        (string-append "-DDEVICE=GPU_SM"#$mycudaarch))
                #$flags))
      ))
      (inputs
        (modify-inputs (package-inputs proxy-geos-raja-cuda)
          (delete "camp-cuda")
          (delete "raja-cuda")
          (delete "chai-cuda")
          (append camp-cuda-arch)
          (append raja-cuda-arch)
          (append chai-cuda-arch))
      ))
)

(define-public proxy-geos-raja-cuda-ada
  (make-proxy-geos-raja-cuda-arch "proxy-geos-raja-cuda-ada" "89" camp-cuda-ada raja-cuda-ada chai-cuda-ada))


;; HIP packaging KOKKOS

(define (make-proxy-geos-kokkos-hip name kokkos-hip myhiparch)
  (package/inherit proxy-geos-kokkos
  (name name)
  (arguments (substitute-keyword-arguments (package-arguments proxy-geos-kokkos)
                 ((#:configure-flags flags)
                  #~(append (list (string-append "-DCMAKE_HIP_ARCHITECTURES="#$myhiparch)
                                  "-DENABLE_HIP=ON"
                                  (string-append "-DROCM_PATH="#$(this-package-input "hipamd"))
                                  (string-append "-DDEVICE=GPU_"#$myhiparch))
                              #$flags))
                 ;; Cannot run tests due to lack of specific hardware
                 ((#:tests? _ #t)
                  #f)
                 ;; RUNPATH validation fails
                 ((#:validate-runpath? #f #f)
                  #f)))
  (inputs (modify-inputs (package-inputs proxy-geos-kokkos)
      (delete "kokkos")
      (append kokkos-hip)
      (append rocprim)
      (prepend hipamd)))))

(define-public proxy-geos-kokkos-hip-vega900
  (make-proxy-geos-kokkos-hip "proxy-geos-kokkos-hip-vega900" kokkos-hip-vega900 "gfx900"))

(define-public proxy-geos-kokkos-hip-vega906
  (make-proxy-geos-kokkos-hip "proxy-geos-kokkos-hip-vega906" kokkos-hip-vega906 "gfx906"))

(define-public proxy-geos-kokkos-hip-vega908
  (make-proxy-geos-kokkos-hip "proxy-geos-kokkos-hip-vega908" kokkos-hip-vega908 "gfx908"))

(define-public proxy-geos-kokkos-hip-vega90A
  (make-proxy-geos-kokkos-hip "proxy-geos-kokkos-hip-vega90A" kokkos-hip-vega90A "gfx90A"))

;; ;; This allows you to run guix shell -f proxy-geosx-hc.scm.
;; ;; Remove this line if you just want to define a package.
;; ;; proxy-geos-hc
