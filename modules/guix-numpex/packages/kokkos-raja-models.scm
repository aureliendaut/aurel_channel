;;; This module extends GNU Guix and is licensed under the same terms, those
;;; of the GNU GPL version 3 or (at your option) any later version.
;;;
;;; Copyright © 2024 Inria

(define-module (guix-numpex_pc5 packages kokkos-raja-models)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix packages)
  #:use-module (gnu packages)
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


;; umpire-cuda for various arichecture 
(define (make-umpire-cuda-spec-compute name cuda-arch-compute)
  (package/inherit umpire
    (name name)
    (arguments (substitute-keyword-arguments (package-arguments umpire)
                 ((#:configure-flags flags)
                  #~(append (list (string-append "-DCMAKE_CUDA_ARCHITECTURES="#$cuda-arch-compute))
			    (list (string-append "-DCUDA_ARCH=sm_"#$cuda-arch-compute))
			          #$flags
                            ))
		 ))
    ;;(inputs (list cuda openmpi blt openssh-sans-x))
    ))

(define-public umpire-cuda-ada
  (make-umpire-cuda-spec-compute "umpire-cuda-ada" "89"))
(define-public umpire-cuda-v100
  (make-umpire-cuda-spec-compute "umpire-cuda-v100" "70"))
(define-public umpire-cuda-t4
  (make-umpire-cuda-spec-compute "umpire-cuda-t4" "75"))
(define-public umpire-cuda-p100
  (make-umpire-cuda-spec-compute "umpire-cuda-p100" "60"))
(define-public umpire-cuda-k40
  (make-umpire-cuda-spec-compute "umpire-cuda-k40" "35"))
(define-public umpire-cuda-a40
  (make-umpire-cuda-spec-compute "umpire-cuda-a40" "86"))
(define-public umpire-cuda-a100
  (make-umpire-cuda-spec-compute "umpire-cuda-a100" "80"))

;; This creates a chai-cuda where openmp and cuda are enabled throughout inheritence from chai-cuda and specification of a different compute capability
;;(define (make-append-cuda name cudaflag)
;;  (* #$name-#$cudaflag))

;;(define (make-append-cuda name cudaflag)
;;  (* #$name-#$cudaflag))
;;(define (make-append-cuda name cudaflag)
;;  (#$name))
(define (make-chai-cuda-spec-compute name cudaflag cuda-arch-compute)
  (package/inherit chai-cuda
    (name name)
    (inputs (modify-inputs (package-inputs chai-cuda)
			   (delete "camp-cuda")
			   (delete "raja-cuda")
			   (delete "umpire")
			   (append camp-cuda-ada)
			   (append raja-cuda-ada)
			   (append umpire-cuda-ada)
			   ;;(append (#:make-append-cuda raja-cuda ada))
			   ;;(replace "raja-cuda" #:(raja-cuda-#$cudaflag))
			   ;;(append (string-append "camp-cuda-" cudaflag))
			   ;;(append (string-append "camp-cuda-"#$cuda-arch-string))
			   ;;(append (lookup-package-input this-package (string-append "raja-cuda-"#$cudaflag)))
			   ))
    (arguments (substitute-keyword-arguments (package-arguments chai-cuda)
                 ((#:configure-flags flags)
                  #~(append (list (string-append "-DCMAKE_CUDA_ARCHITECTURES="#$cuda-arch-compute)
				  (string-append "-DCUDA_ARCH=sm_"#$cuda-arch-compute))
			          (delete "-DCMAKE_CUDA_ARCHITECTURES=70" (delete "-DCUDA_ARCH=sm_70" #$flags))
                            ))
		 ))
    ))

(define-public chai-cuda-ada
  (make-chai-cuda-spec-compute "chai-cuda-ada" "ada" "89"))
;;(define-public chai-cuda-v100
;;  (make-chai-cuda-spec-compute "chai-cuda-v100" "v100" "70"))
;;(define-public chai-cuda-t4
;;  (make-chai-cuda-spec-compute "chai-cuda-t4" "t4" "75"))
;;(define-public chai-cuda-p100
;;  (make-chai-cuda-spec-compute "chai-cuda-p100" "p100" "60"))
;;(define-public chai-cuda-k40
;;  (make-chai-cuda-spec-compute "chai-cuda-k40" "k40" "35"))
;;(define-public chai-cuda-a40
;;  (make-chai-cuda-spec-compute "chai-cuda-a40" "a40" "86"))
;;(define-public chai-cuda-a100
;;  (make-chai-cuda-spec-compute "chai-cuda-a100" "a100" "80"))


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

(define-public kokkos-hip-vega900
  (make-kokkos-hip-spec-architecture "kokkos-hip-vega900" "VEGA900"))

(define-public kokkos-hip-vega906
  (make-kokkos-hip-spec-architecture "kokkos-hip-vega906" "VEGA906"))

(define-public kokkos-hip-vega908
  (make-kokkos-hip-spec-architecture "kokkos-hip-vega908" "VEGA90A"))

(define-public kokkos-hip-vega90A
  (make-kokkos-hip-spec-architecture "kokkos-hip-vega90A" "VEGA90A"))

;; This creates a template for enabling OpenMP on top of a given kokkos-cuda-<arch>                                                                                                                                                                                                                
(define (make-kokkos-hip-openmp name kokkos-hip-arch)
  (package/inherit kokkos-hip-arch
    (name name)
    (arguments (substitute-keyword-arguments (package-arguments kokkos-hip-arch)
                 ((#:configure-flags flags)
                  #~(append (list "-DKokkos_ENABLE_OPENMP=ON")
                            #$flags))
                 ;; Cannot run tests due to lack of specific hardware                                                                                                                                                                                                                              
                 ((#:tests? _ #t)
                  #f)
                 ;; RUNPATH validation fails                                                                   
                 ((#:validate-runpath? #f #f)
                  #f)
                 ((#:phases phases
                   '%standard-phases)
                  #~(modify-phases #$phases
                      ;; File is not present in CUDA build                                                                                                                                                                                                                                         
                      ))
                 ))
    ))


(define-public kokkos-hip-vega900-openmp
  (make-kokkos-hip-openmp "kokkos-hip-vega900-openmp" kokkos-hip-vega900))

(define-public kokkos-hip-vega906-openmp
  (make-kokkos-hip-openmp "kokkos-hip-vega906-openmp" kokkos-hip-vega906))

(define-public kokkos-hip-vega908-openmp
  (make-kokkos-hip-openmp "kokkos-hip-vega908-openmp" kokkos-hip-vega908))

(define-public kokkos-hip-vega90A-openmp
  (make-kokkos-hip-openmp "kokkos-hip-vega90A-openmp" kokkos-hip-vega90A))


