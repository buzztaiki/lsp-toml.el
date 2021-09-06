;;; lsp-toml.el --- LSP support for TOML, using taplo-lsp -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Taiki Sugawara

;; Author: Taiki Sugawara <buzz.taiki@gmail.com>
;; Keywords: lsp, toml

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; 

;;; Code:

(require 'lsp-mode)
(require 'ht)

(defgroup lsp-toml nil
  "LSP support for TOML, using taplo-lsp."
  :group 'lsp-mode
  :link '(url-link "https://taplo.tamasfe.dev/lsp/"))

(defcustom lsp-toml-taplo-lsp-command "taplo-lsp"
  "Path to taplo-lsp command."
  :group 'lsp-toml
  :type 'string)

(defcustom lsp-toml-taplo-config nil
  "An absolute, or workspace relative path to the Taplo configuration file."
  :type 'string)
(defcustom lsp-toml-taplo-config-enabled t
  "Whether to enable the usage of a Taplo configuration file."
  :type 'boolean)

(defcustom lsp-toml-schema-enabled t
  "Enable completion and validation based on JSON schemas."
  :type 'boolean)
(defcustom lsp-toml-schema-links nil
  "Enable editor links."
  :type 'boolean)
(defcustom lsp-toml-schema-repository-enabled t
  "Whether to use schemas from the provided schema repository."
  :type 'boolean)
(defcustom lsp-toml-schema-repository-url "https://taplo.tamasfe.dev/schema_index.json"
  "A HTTP(S) URL that points to a schema index."
  :type 'string)
(defcustom lsp-toml-schema-associations
  `((,(make-symbol "^(.*(/|\\\\)\\.?taplo\\.toml|\\.?taplo\\.toml)$") . "taplo://taplo.toml"))
  "Document and schema associations."
  :type '(alist :key-type symbol :value-type string))

(defcustom lsp-toml-formatter-align-entries nil
  "Align consecutive entries vertically."
  :type 'boolean)
(defcustom lsp-toml-formatter-align-comments t
  "Align comments vertically after entries and array values."
  :type 'boolean)
(defcustom lsp-toml-formatter-array-trailing-comma t
  "Append trailing commas for multi-line arrays."
  :type 'boolean)
(defcustom lsp-toml-formatter-array-auto-expand t
  "Expand arrays to multiple lines that exceed the maximum column width."
  :type 'boolean)
(defcustom lsp-toml-formatter-array-auto-collapse t
  "Collapse arrays that don't exceed the maximum column width and don't contain comments."
  :type 'boolean)
(defcustom lsp-toml-formatter-compact-arrays t
  "Omit white space padding from single-line arrays."
  :type 'boolean)
(defcustom lsp-toml-formatter-compact-inline-tables nil
  "Omit white space padding from the start and end of inline tables."
  :type 'boolean)
(defcustom lsp-toml-formatter-compact-entries nil
  "Omit white space padding around `=` for entries."
  :type 'boolean)
(defcustom lsp-toml-formatter-column-width 80
  "Maximum column width in characters, affects array expansion and collapse, this doesn't take whitespace into account."
  :type 'number)
(defcustom lsp-toml-formatter-indent-tables nil
  "Indent based on tables and arrays of tables and their subtables, subtables out of order are not indented."
  :type 'boolean)
(defcustom lsp-toml-formatter-indent-entries nil
  "Indent entries under tables."
  :type 'boolean)
(defcustom lsp-toml-formatter-indent-string nil
  "The substring that is used for indentation, should be tabs or spaces, but technically can be anything.  Uses the IDE setting if not set."
  :type '(repeat string))
(defcustom lsp-toml-formatter-reorder-keys nil
  "Alphabetically reorder keys that are not separated by empty lines."
  :type 'boolean)
(defcustom lsp-toml-formatter-allowed-blank-lines 2
  "Maximum amount of allowed consecutive blank lines.  This does not affect the whitespace at the end of the document, as it is always stripped."
  :type 'number)
(defcustom lsp-toml-formatter-trailing-newline t
  "Add trailing newline at the end of the file if not present."
  :type 'boolean)
(defcustom lsp-toml-formatter-crlf nil
  "Use CRLF for line endings."
  :type 'boolean)


(lsp-register-custom-settings
 '(
   ("evenBetterToml.taploConfigEnabled" lsp-toml-taplo-config-enabled t)
   ("evenBetterToml.taploConfig" lsp-toml-taplo-config)

   ("evenBetterToml.schema.associations" lsp-toml-schema-associations)
   ("evenBetterToml.schema.repositoryUrl" lsp-toml-schema-repository-url)
   ("evenBetterToml.schema.repositoryEnabled" lsp-toml-schema-repository-enabled t)
   ("evenBetterToml.schema.links" lsp-toml-schema-links t)
   ("evenBetterToml.schema.enabled" lsp-toml-schema-enabled t)

   ("evenBetterToml.formatter.crlf" lsp-toml-formatter-crlf t)
   ("evenBetterToml.formatter.trailingNewline" lsp-toml-formatter-trailing-newline t)
   ("evenBetterToml.formatter.allowedBlankLines" lsp-toml-formatter-allowed-blank-lines)
   ("evenBetterToml.formatter.reorderKeys" lsp-toml-formatter-reorder-keys t)
   ("evenBetterToml.formatter.indentString" lsp-toml-formatter-indent-string)
   ("evenBetterToml.formatter.indentEntries" lsp-toml-formatter-indent-entries t)
   ("evenBetterToml.formatter.indentTables" lsp-toml-formatter-indent-tables t)
   ("evenBetterToml.formatter.columnWidth" lsp-toml-formatter-column-width)
   ("evenBetterToml.formatter.compactEntries" lsp-toml-formatter-compact-entries t)
   ("evenBetterToml.formatter.compactInlineTables" lsp-toml-formatter-compact-inline-tables t)
   ("evenBetterToml.formatter.compactArrays" lsp-toml-formatter-compact-arrays t)
   ("evenBetterToml.formatter.arrayAutoCollapse" lsp-toml-formatter-array-auto-collapse t)
   ("evenBetterToml.formatter.arrayAutoExpand" lsp-toml-formatter-array-auto-expand t)
   ("evenBetterToml.formatter.arrayTrailingComma" lsp-toml-formatter-array-trailing-comma t)
   ("evenBetterToml.formatter.alignComments" lsp-toml-formatter-align-comments t)
   ("evenBetterToml.formatter.alignEntries" lsp-toml-formatter-align-entries t)

   ("evenBetterToml.taploConfigEnabled" lsp-toml-taplo-config-enabled t)
   ("evenBetterToml.taploConfig" lsp-toml-taplo-config)
   ))


(defun lsp-toml--update-configuration (workspace)
  (with-lsp-workspace workspace
    (lsp--set-configuration (lsp-configuration-section "evenBetterToml"))))

(defun lsp-toml--initialization-options ()
  (list :configuration (ht-get (lsp-configuration-section "evenBetterToml") "evenBetterToml")))

(lsp-register-client
 (make-lsp-client
  :new-connection (lsp-stdio-connection (list lsp-toml-taplo-lsp-command "run"))
  :activation-fn (lsp-activate-on "toml")
  :initialized-fn #'lsp-toml--update-configuration
  :initialization-options #'lsp-toml--initialization-options
  :server-id 'taplo-lsp
  :priority 0))

(lsp-consistency-check lsp-toml)
(add-to-list 'lsp-language-id-configuration '(conf-toml-mode . "toml"))
(add-to-list 'lsp-language-id-configuration '(toml-mode . "toml"))


(provide 'lsp-toml)
;;; lsp-toml.el ends here
