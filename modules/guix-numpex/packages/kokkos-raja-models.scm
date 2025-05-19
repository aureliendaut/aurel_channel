;;; This module extends GNU Guix and is licensed under the same terms, those
;;; of the GNU GPL version 3 or (at your option) any later version.
;;;
;;; Copyright © 2024 Inria

(define-module (guix-numpex packages kokkos-raja-models)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix packages)
  #:use-module (gnu packages)
  #:use-module (gnu packages python)
  #:use-module (gnu packages base)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages cpp)
  #:use-module (guix-hpc-non-free packages cpp)
  #:use-module (guix-hpc packages cpp)
  #:use-module (llnl tainted geos)
  #:use-module (llnl geos)
  #:use-module (guix-science-nonfree packages cuda))

;; This creates a template for enabling OpenMP on top of a given kokkos-cuda-<arch> 
(define (make-kokkos-cuda-openmp name kokkos-cuda-arch)
  (package/inherit kokkos-cuda-arch
    (name name)
    (arguments (substitute-keyword-arguments (package-arguments kokkos-cuda-arch)
                 ((#:configure-flags flags)
                  #~(append (list "-DKokkos_ENABLE_OPENMP=ON")
                            #$flags))
                 ;; Cannot run tests due to lack of specific hardware
                 ((#:tests? _ #t)
                  #f)
                 ;; RUNPATH validation fails since libcuda.so.1 is not present at build
                 ;; time.
                 ((#:validate-runpath? #f #f)
                  #f)
                 ((#:phases phases
                   '%standard-phases)
                  #~(modify-phases #$phases
                      ;; File is not present in CUDA build
                      ))
		 ))
    ))

(define-public kokkos-cuda-k40-openmp
  (make-kokkos-cuda-openmp "kokkos-cuda-k40-openmp" kokkos-cuda-k40))

(define-public kokkos-cuda-a40-openmp
  (make-kokkos-cuda-openmp "kokkos-cuda-a40-openmp" kokkos-cuda-a40))

(define-public kokkos-cuda-a100-openmp
  (make-kokkos-cuda-openmp "kokkos-cuda-a100-openmp" kokkos-cuda-a100))

(define-public kokkos-cuda-v100-openmp
  (make-kokkos-cuda-openmp "kokkos-cuda-v100-openmp" kokkos-cuda-v100))

(define-public kokkos-cuda-p100-openmp
  (make-kokkos-cuda-openmp "kokkos-cuda-p100-openmp" kokkos-cuda-p100))

(define-public kokkos-cuda-ada-openmp
  (make-kokkos-cuda-openmp "kokkos-cuda-ada-openmp" kokkos-cuda-ada))

(define-public kokkos-cuda-t4-openmp
  (make-kokkos-cuda-openmp "kokkos-cuda-t4-openmp" kokkos-cuda-t4))


;; This creates a raja-cuda where openmp and cuda are enabled throughout inheritence from raja-cuda and specification of a different compute capability
(define (make-raja-cuda-spec-compute name cuda-arch-compute)
  (package/inherit raja-cuda
    (name name)
    (arguments (substitute-keyword-arguments (package-arguments raja-cuda)
                 ((#:configure-flags flags)
                  #~(append (list (string-append "-DCMAKE_CUDA_ARCHITECTURES="#$cuda-arch-compute))
			          (delete "-DCMAKE_CUDA_ARCHITECTURES=70" #$flags)
                            ))
		 ))
    ))
(define-public raja-cuda-ada
  (make-raja-cuda-spec-compute "raja-cuda-ada" "89"))
(define-public raja-cuda-v100
  (make-raja-cuda-spec-compute "raja-cuda-v100" "70"))
(define-public raja-cuda-t4
  (make-raja-cuda-spec-compute "raja-cuda-t4" "75"))
(define-public raja-cuda-p100
  (make-raja-cuda-spec-compute "raja-cuda-p100" "60"))
(define-public raja-cuda-k40
  (make-raja-cuda-spec-compute "raja-cuda-k40" "35"))
(define-public raja-cuda-a40
  (make-raja-cuda-spec-compute "raja-cuda-a40" "86"))
(define-public raja-cuda-a100
  (make-raja-cuda-spec-compute "raja-cuda-a100" "80"))

;; camp-cuda for various arichecture 
(define (make-camp-cuda-spec-compute name cuda-arch-compute)
  (package/inherit camp-cuda
    (name name)
    (arguments (substitute-keyword-arguments (package-arguments camp-cuda)
                 ((#:configure-flags flags)
                  #~(append (list (string-append "-DCMAKE_CUDA_ARCHITECTURES="#$cuda-arch-compute))
			    (list (string-append "-DCUDA_ARCH=sm_"#$cuda-arch-compute))
			          #$flags
                            ))
		 ))
    ))

(define-public camp-cuda-ada
  (make-camp-cuda-spec-compute "camp-cuda-ada" "89"))
(define-public camp-cuda-v100
  (make-camp-cuda-spec-compute "camp-cuda-v100" "70"))
(define-public camp-cuda-t4
  (make-camp-cuda-spec-compute "camp-cuda-t4" "75"))
(define-public camp-cuda-p100
  (make-camp-cuda-spec-compute "camp-cuda-p100" "60"))
(define-public camp-cuda-k40
  (make-camp-cuda-spec-compute "camp-cuda-k40" "35"))
(define-public camp-cuda-a40
  (make-camp-cuda-spec-compute "camp-cuda-a40" "86"))
(define-public camp-cuda-a100
  (make-camp-cuda-spec-compute "camp-cuda-a100" "80"))

;; This creates a chai-cuda where openmp and cuda are enabled throughout inheritence from chai-cuda and specification of a different

(define-public make-chai
  (package
    (name "make-chai")
    (version "2023.06.0")
    (home-page "https://github.com/LLNL/CHAI")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url home-page)
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "16qjnx1bvddiyhp1g0f17hral88361f7mjm365iy144dv0ar50yw"))))
    (build-system cmake-build-system)
    (arguments
     (list #:configure-flags #~`("-DENABLE_OPENMP=ON"
                                 ,(string-append
                                     "-DBLT_SOURCE_DIR="
                                     #$(this-package-input
                                        "blt") "/blt_dir")
                                 ,(string-append "-Dcamp_DIR=" #$(this-package-input "camp"))
                                 "-DCMAKE_CUDA_STANDARD=14"
                                 "-DBUILD_SHARED_LIBS=ON"
                                 "-DCHAI_ENABLE_TESTS=OFF"
                                 "-DENABLE_TESTS=OFF"
                                 "-DENABLE_GTEST_DEATH_TESTS=OFF"
                                 "-Dgtest_disable_pthreads=OFF"
                                 "-DENABLE_EXAMPLES:BOOL=OFF"
                                 "-DCHAI_ENABLE_EXAMPLES=OFF"
                                 "-DENABLE_BENCHMARKS=OFF"
                                 "-DCHAI_ENABLE_BENCHMARKS=OFF"
                                 "-DENABLE_DOXYGEN=OFF"
                                 "-DENABLE_DOCS=OFF"
                                 "-DENABLE_SPHINX=OFF"
                                 "-DENABLE_GMOCK=OFF"
                                 "-DRAJA_ENABLE_EXERCISES=OFF"
                                 "-DCHAI_ENABLE_RAJA_PLUGIN=ON"
                                 "-DENABLE_GTEST=ON"
                                 ,(string-append "-DRAJA_DIR=" #$(this-package-input "raja") "/lib/cmake/raja")
                                 "-DUMPIRE_ENABLE_C=ON")
            #:tests? #f
     #:phases
              #~(modify-phases %standard-phases
                (add-after 'unpack 'copy-umpire-sources
                   (lambda _
                     (begin
                       (rmdir "src/tpl/umpire")
                       (copy-recursively (string-append #$(this-package-input
                                          "umpire") "/umpire_dir") "src/tpl/umpire")))))


           ))
    (inputs (list blt python raja camp umpire))
    (synopsis "C++ array-style interface for automatic data migration with OpenMP enabled")
    (description
     "CHAI is a C++ libary providing an array object that
can be used transparently in multiple memory spaces.  Data is
automatically migrated based on copy-construction,
allowing for correct data access regardless of location.  CHAI
can be used standalone, but is best when paired with the RAJA
library, which has built-in CHAI integration that takes care of everything")
    (license license:bsd-3)))

(define (make-chai-cuda-with-raja-camp-arch name raja-cuda-arch camp-cuda-arch cuda-package cuda-arch-compute)
  (package/inherit make-chai
    (name name)
    (inputs (modify-inputs (package-inputs make-chai)
			   (replace "camp" camp-cuda-arch)
			   (replace "raja" raja-cuda-arch)
			   (append cuda-package)))
    (arguments (substitute-keyword-arguments (package-arguments make-chai)
                 ((#:configure-flags flags)
                  #~(append #$flags
                            ;; No need to delete the inherited camp_DIR, RAJA_DIR. Just append after to consider the latest arg. for cmake.
                            (list "-DENABLE_CUDA=ON"
                                  (string-append "-DCUDA_TOOLKIT_ROOT_DIR=" #$(this-package-input "cuda-toolkit"))
                                  (string-append "-Dcamp_DIR=" (quote #$camp-cuda-arch))
                                  (string-append "-DRAJA_DIR=" (quote #$raja-cuda-arch) "/lib/cmake/raja")
                                  (string-append "-DCMAKE_CUDA_ARCHITECTURES="#$cuda-arch-compute)
                                  (string-append "-DCUDA_ARCH=sm_"#$cuda-arch-compute)
                                  )
                            ))
    ))
    (synopsis "C++ array-style interface for automatic data migration with both CUDA and OpenMP backends enabled")
    (description
     "CHAI is a C++ libary providing an array object that
can be used transparently in multiple memory spaces.  Data is
automatically migrated based on copy-construction,
allowing for correct data access regardless of location.  CHAI
can be used standalone, but is best when paired with the RAJA
library, which has built-in CHAI integration that takes care of everything")
    (license license:bsd-3)))

(define-public chai-cuda-ada
  (make-chai-cuda-with-raja-camp-arch "chai-cuda-ada" raja-cuda-ada camp-cuda-ada cuda "89"))
(define-public chai-cuda-v100
 (make-chai-cuda-with-raja-camp-arch "chai-cuda-v100" raja-cuda-v100 camp-cuda-v100 cuda "70"))
(define-public chai-cuda-t4
 (make-chai-cuda-with-raja-camp-arch "chai-cuda-t4" raja-cuda-t4 camp-cuda-t4 cuda "75"))
(define-public chai-cuda-p100
 (make-chai-cuda-with-raja-camp-arch "chai-cuda-p100" raja-cuda-p100 camp-cuda-p100 cuda "60"))
(define-public chai-cuda-k40
 (make-chai-cuda-with-raja-camp-arch "chai-cuda-k40" raja-cuda-k40 camp-cuda-k40 cuda "35"))
(define-public chai-cuda-a40
 (make-chai-cuda-with-raja-camp-arch "chai-cuda-a40" raja-cuda-a40 camp-cuda-a40 cuda "86"))
(define-public chai-cuda-a100
 (make-chai-cuda-with-raja-camp-arch "chai-cuda-a100" raja-cuda-a100 camp-cuda-a100 cuda "80"))

;;This create a kokkos-hip package related to a specific architecture

(define (make-kokkos-hip-spec-architecture name hip-arch)
  (package/inherit kokkos-hip
    (name name)
    (arguments
     (substitute-keyword-arguments (package-arguments kokkos-hip)
       ((#:configure-flags flags)
        #~(append (list (string-append "-DKokkos_ARCH_" #$hip-arch "=ON"))
                  (delete "-DKokkos_ARCH_VEGA90A=ON" #$flags)
                  ))
       ))
    ))

(define-public kokkos-hip-vega906
  (make-kokkos-hip-spec-architecture "kokkos-hip-vega906" "VEGA906"))



