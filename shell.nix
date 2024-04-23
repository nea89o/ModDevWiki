let
  pkgs = import <nixpkgs> {};
in pkgs.mkShell {
	buildInputs = [
		(pkgs.python3.withPackages (python-pkgs: [python-pkgs.virtualenv]))
		pkgs.cairo
	];
	shellHook = ''
		export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.cairo}/lib"
		python -m venv "$PWD"/venv
		source "$PWD"/venv/bin/activate
	'';
}
