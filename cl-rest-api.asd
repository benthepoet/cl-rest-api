#|
 This file is a part of cl-rest-api
 (c) 2018 Ben Hanna (benpaulhanna@gmail.com)
 Author: Ben Hanna <benpaulhanna@gmail.com>
|#

(in-package #:cl-user)
(asdf:defsystem rest-api
  :version "0.0.0"
  :license "BSD-3"
  :author "Ben Hanna <benpaulhanna@gmail.com>"
  :maintainer "Ben Hanna <benpaulhanna@gmail.com>"
  :description ""
  :serial T
  :components ((:file "package"))
  :depends-on (:cl-ppcre
               :hunchentoot
               :sqlite
               :yason))
