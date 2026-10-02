; extends

;; Fenced code blocks (``` ... ``` or ~~~ ... ~~~)
;; - @codeblock.outer: entire block including both fence delimiter lines
;; - @codeblock.inner: only the content between the fences
(fenced_code_block
  (code_fence_content) @codeblock.inner) @codeblock.outer
