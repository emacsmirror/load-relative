(provide 'load-relative)
(defun __FILE__ (&optional symbol)
  "Return the string name of file/buffer that is currently begin executed.

The first approach for getting this information is perhaps the
most pervasive and reliable. But it the most low-level and not
part of a public API, so it might change in future
implementations. This method uses the name that is recorded by
readevalloop of `lread.c' as the car of variable
`current-load-list'.

Failing that, we use `load-file-name' which should work in some
subset of the same places that the first method works. However
`load-file-name' will be nil for code that is eval'd. To cover
those cases, we try `buffer-file-name' which is initially
correct, for eval'd code, but will change and may be wrong if the
code sets or switches buffers after the initial execution.

Failing the above the next approach we try is to use the value of
$# - 'the name of this file as a string'. Although it doesn't
work for eval-like things, it has the advantage that this value
persists after loading or evaluating a file. So it would be
suitable if __FILE__ were called from inside a function.

As a last resort, you can pass in SYMBOL which should be some
symbol that has been previously defined if none of the above
methods work we will use the file-name value find via
`symbol-file'."
  (cond 
     ;; lread.c's readevalloop sets (car current-load-list)
     ;; via macro LOADHIST_ATTACH of lisp.h. At least in Emacs
     ;; 23.0.91 and this code goes back to '93.
     ((stringp (car-safe current-load-list)) (car current-load-list))

     ;; load-like things. 'relative-file-expand' tests in
     ;; test/test-load.el indicates we should put this ahead of
     ;; $#.
     (load-file-name)  

     ;; Pick up "name of this file as a string" which is set on
     ;; reading and persists. In contrast, load-file-name is set only
     ;; inside eval. As such, it won't work when not in the middle of
     ;; loading.
     ;; (#$) 

     ((buffer-file-name))     ;; eval-like things
     (t (symbol-file symbol)) ;; last resort
     ))

(defun load-relative (file-or-list &optional symbol)
  "Load an Emacs Lisp file relative to Emacs Lisp code that is in
the process of being loaded or eval'd.

FILE-OR-LIST is either a string or a list of strings containing
files that you want to loaded.

WARNING: it is best to to run this function before any
buffer-setting or buffer changing operations."

  (if (listp file-or-list)
      (mapcar (lambda(relative-file)
		(load (relative-expand-file-name relative-file symbol)))
		file-or-list)
    (load (relative-expand-file-name file-or-list symbol))))

(defun relative-expand-file-name(relative-file &optional opt-file)
  "Expand RELATIVE-FILE relative to the Emacs Lisp code that is in
the process of being loaded or eval'd."
  (let* ((file (or opt-file (__FILE__) default-directory))
	 (prefix (file-name-directory file)))
    (expand-file-name (concat prefix relative-file))))

(defun require-relative (relative-file &optional opt-file)
  "Run `require' on an Emacs Lisp file relative to the Emacs Lisp code
that is in the process of being loaded or eval'd.

WARNING: it is best to to run this function before any
buffer-setting or buffer changing operations."
  (let ((require-string-name 
	 (file-name-sans-extension 
	  (file-name-nondirectory relative-file))))
    (require (intern require-string-name) 
	       (relative-expand-file-name relative-file opt-file))))

(defmacro require-relative-list (list)
  `(progn 
     (eval-when-compile
       (require 'cl
		(dolist (rel-file ,list)
		  (require-relative rel-file (__FILE__))))
     (dolist (rel-file ,list)
       (require-relative rel-file (__FILE__))))))
