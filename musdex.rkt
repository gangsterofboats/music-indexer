#lang racket
(require db)
(require file/glob)

;; Parse arguments
(define input-path null)
(define output-path null)

(command-line
 #:once-each
 [("-i" "--input") input "Input path" (set! input-path input)]
 [("-o" "--output") output "Output path" (set! output-path output)])

;; Ensure directory paths end in slashes
(unless (string-suffix? input-path "/")
  (set! input-path (string-append input-path "/")))
(unless (string-suffix? output-path "/")
  (set! output-path (string-append output-path "/")))

;; Main part of script
(define mp3s (glob (string-append input-path "**.mp3")))
(define database (string-append output-path "music.db"))
(define dbc (sqlite3-connect #:database database #:mode 'create))
(query-exec dbc "CREATE TABLE music (id INTEGER PRIMARY KEY, artist TEXT, title TEXT, album TEXT, year TEXT, genre TEXT)")
(for ([f mp3s])
  (define info (with-output-to-string (lambda () (system (format "id3v2 -l \"~a\"" f)))))
  (set! info (string-split info "\n"))
  (set! info (filter (lambda (s) (regexp-match #rx"TIT2|TPE1|TALB|TYER|TCON" s)) info))
  (define tags (make-hash))
  (hash-set*! tags
              'title (regexp-replace #rx"^(.*?)\\)\\: " (first info) "")
              'artist (regexp-replace #rx"^(.*?)\\)\\: " (second info) "")
              'album (regexp-replace #rx"^(.*?)\\)\\: " (third info) "")
              'year (regexp-replace #rx"^(.*?)\\)\\: " (fourth info) "")
              'genre (regexp-replace #rx"^(.*?)\\)\\: " (fifth info) ""))
  (hash-set! tags 'genre  (regexp-replace #rx" \\([0-9]+\\)$" (hash-ref tags 'genre) ""))
  (query-exec dbc "INSERT INTO music (artist, title, album, year, genre) VALUES (?, ?, ?, ?, ?)" (hash-ref tags 'artist) (hash-ref tags 'title) (hash-ref tags 'album) (hash-ref tags 'year) (hash-ref tags 'genre)))
