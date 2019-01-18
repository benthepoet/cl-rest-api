#|
  This file is a part of cl-rest-api
  (c) 2018 Ben Hanna (benpaulhanna@gmail.com)
  Author: Ben Hanna <benpaulhanna@gmail.com>
|#

(defpackage #:cl-rest-api
  (:use #:cl
        #:cl-ppcre
        #:hunchentoot
        #:sqlite
        #:yason)
  (:export #:create-user
           #:define-route
           #:encode-user
           #:encode-users
           #:fetch-user
           #:fetch-users
           #:setup-database
           #:setup-routes
           #:start-server
           #:with-envelope))

(in-package #:cl-rest-api)

;;; Variables
(defvar *api-acceptor* nil)
(defvar *db* nil)

;;; Macros
(defmacro define-route (regex parameters &body body)
  `(push
    (hunchentoot:create-regex-dispatcher
     ,regex
     (lambda ()
       (ppcre:register-groups-bind
         ,parameters
         (,regex (hunchentoot:request-uri*))
         (setf (hunchentoot:content-type*) "application/json")
         (case (hunchentoot:request-method*)
           ,@body
           (otherwise (not-found))))))
    hunchentoot:*dispatch-table*))

(defmacro with-envelope (&body body)
  `(yason:with-output-to-string* ()
     (yason:with-object ()
       (yason:with-object-element ("data")
         ,@body))))

;;; Functions
(defun create-user (name)
  (sqlite:execute-non-query *db* "INSERT INTO users (name) VALUES (?)" name)
  (setf (hunchentoot:return-code*) hunchentoot:+http-created+)
  (format nil ""))

(defun encode-user (id name)
  (with-envelope
    (yason:with-object ()
      (yason:encode-object-element "id" id)
      (yason:encode-object-element "name" name))))

(defun encode-users (users)
  (with-envelope
    (yason:with-array ()
      (loop for (id name) in users do
            (yason:with-object ()
              (yason:encode-object-element "id" id)
              (yason:encode-object-element "name" name))))))

(defun fetch-user (id)
  (car (sqlite:execute-to-list *db* "SELECT * FROM users WHERE id = ?" id)))

(defun fetch-users (name)
  (let ((search (if name name "")))
    (sqlite:execute-to-list *db* (format nil "SELECT * FROM users WHERE name LIKE '~a%'" search))))

(defun not-found ()
  (setf (hunchentoot:return-code*) hunchentoot:+http-not-found+)
  (format nil ""))

(defun setup-database ()
  (let ((queries
          '("CREATE TABLE users (id INTEGER PRIMARY KEY NOT NULL, name VARCHAR(32) NOT NULL)"
            "INSERT INTO users (name) VALUES ('Ben Hanna')")))
    (dolist (query queries) (sqlite:execute-non-query *db* query))))

(defun setup-routes ()
  (setq hunchentoot:*dispatch-table* '(hunchentoot:dispatch-easy-handlers))
  (define-route "^/users/(\\d+)$" (id)
    (:GET (let ((user (fetch-user id)))
            (if user
                (apply 'encode-user user)
                (not-found)))))
  (define-route "^/users(\\?\\S+)?$" ()
    (:GET (let ((name (hunchentoot:get-parameter "name")))
            (encode-users (fetch-users name))))
    (:POST (let ((user (yason:parse (hunchentoot:raw-post-data :force-text t))))
             (create-user (gethash "name" user))))))

(defun start-server (port)
  (if *api-acceptor* (hunchentoot:stop *api-acceptor*))
  (setf *api-acceptor* (make-instance 'hunchentoot:easy-acceptor :port port))

  (if *db* (sqlite:disconnect *db*))
  (setf *db* (sqlite:connect ":memory:"))

  (setup-database)
  (setup-routes)
  
  (hunchentoot:start *api-acceptor*))
