define-command symflower -params .. -docstring %{symflower [<args>...]: generate unit tests

Results are summarized in the *symflower* scratch buffer.
Any arguments are forwarded to the 'symflower' command.
} %{ evaluate-commands %sh{
	output=$(mktemp -d "${TMPDIR:-/tmp}"/symflower-kakoune.XXXXXXXX)/fifo
	mkfifo ${output}
	( symflower "$@" > ${output} 2>&1 & ) >/dev/null 2>&1 </dev/null

	printf %s\\n "evaluate-commands -draft %{
		edit! -fifo ${output} -scroll *symflower*
		hook -always -once buffer BufCloseFifo .* %{ nop %sh{ rm -r $(dirname ${output}) } }
	}"
}}

define-command symflower-enable -docstring "Enable unit test generation on save" %{
	hook -group symflower global BufWritePost .*[.](go|java) symflower
}

define-command symflower-disable -docstring "Disable unit test generation on save" %{
	remove-hooks global symflower
}

define-command symflower-alternative-file -docstring 'Jump to the alternate file (implementation ↔ Symflower test)' %{ evaluate-commands %sh{
	case "$kak_buffile" in
	(*_symflower_test.go)
		altfile=${kak_buffile%_symflower_test.go}.go
		test ! -f "$altfile" && echo "fail 'implementation file not found'" && exit
		;;
	(*_test.go)
		altfile=${kak_buffile%_test.go}.go
		test ! -f "$altfile" && echo "fail 'implementation file not found'" && exit
		;;
	(*.go)
		altfile=${kak_buffile%.go}_symflower_test.go
		test ! -f "$altfile" && echo "fail 'Symflower test file not found'" && exit
		;;
	(*.java)
		altfile=${kak_buffile%.java}SymflowerTest.java
		test ! -f "$altfile" && echo "fail 'Symflower test file not found'" && exit
		;;
	(*SymflowerTest.java)
		altfile=${kak_buffile%SymflowerTest.java}.java
		test ! -f "$altfile" && echo "fail 'implementation file not found'" && exit
		;;
	(*)
		echo "fail 'alternative file not found'" && exit
		;;
	esac
	printf "edit -- '%s'" "$(printf %s "$altfile" | sed "s/'/''/g")"
}}
