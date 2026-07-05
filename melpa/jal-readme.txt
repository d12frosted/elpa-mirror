NOTE: This package handles JVM bytecode instrumentation agents, NOT
artificial intelligence (AI) agents.

Java Agent Loader (JAL) automates the manual injection of `-javaagent'
arguments into the JDT Language Server (JDTLS) process used by development
environments like `lsp-java' or `eglot-java'.

In the Java ecosystem, a "Java Agent" is a native JVM plugin that uses
bytecode instrumentation to modify compiled code on the fly as it loads
(powering tools like Lombok or JaCoCo). This technology dates back to 2004
(Java 5) and has absolutely no relation to AI assistants, LLMs, or autonomous
software agents.

JAL bridges the gap between your project's Maven (pom.xml) or Gradle build
configuration and your Emacs LSP client. It utilizes global path caching to
completely bypass slow build-tool CLI lookups, ensuring your Java projects
start instantly on every file visit.
