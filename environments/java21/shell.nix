{ pkgs ? import <nixpkgs> {} }:

let
  # Pinned to JDK 21 (LTS) — change deliberately and test against all build tools
  myJdk = pkgs.jdk21;
in

pkgs.mkShell {
  name = "java21-dev";

  # nativeBuildInputs is preferred over buildInputs for build-time tooling
  nativeBuildInputs = [
    myJdk       # JDK 21 (LTS)
    pkgs.maven  # Dependency management
    pkgs.ant    # XML-based build automation
    pkgs.gradle # Multi-project build tooling
  ];

  shellHook = ''
    export JAVA_HOME="${myJdk.home}"

    echo "Java 21 Development Environment"
    echo "JAVA_HOME: $JAVA_HOME"
    echo ""
    echo "  Java:   $(java -version 2>&1 | head -n 1)"
    echo "  Maven:  $(mvn -v 2>/dev/null | grep 'Apache Maven')"
    echo "  Ant:    $(ant -version 2>/dev/null)"
    echo "  Gradle: $(gradle -v 2>/dev/null | grep '^Gradle')"
    echo ""
  '';
}
