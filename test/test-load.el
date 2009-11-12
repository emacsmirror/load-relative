(require 'cl)
(load-file "./behave.el")
(load-file "../load-relative.el")

(provide 'test-load)
(behave-clear-contexts)

(context "load-relative"
	 (tag load-relative)
	 (specify "relative-expand-filename"
		  (dolist (file-name 
			   '("load-file1.el" "./load-file1.el" "../test/load-file1.el"))
		    (assert-equal 
		     (expand-file-name file-name)
		     (relative-expand-file-name file-name 'test-load))))

	 (specify "Basic load-relative"
		  (dolist (file-name 
			   '("load-file1.el" "./load-file1.el" "../test/load-file1.el"))
		    (setq loaded-file nil)
		    (assert-equal t (load-relative file-name 'test-load))
		    (assert-equal "load-file1" loaded-file)
		    )
		  
		  (setq loaded-file nil)
		  (assert-equal t (load-relative "load-file2" 'test-load))
		  (assert-equal "load-file3" loaded-file 'test-load)

		  (setq loaded-file nil)
		  (setq loaded-file1 nil)
		  (assert-equal '(t t) 
				(load-relative '("load-file1" "load-file2")
					       'test-load))
		  (assert-equal 't loaded-file1)
		  (assert-equal "load-file3" loaded-file))
)

(behave "load-relative")

