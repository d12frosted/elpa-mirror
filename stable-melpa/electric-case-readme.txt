Load this script

  (require 'electric-case)

and initialize in major-mode hooks.

  (add-hook 'java-mode-hook 'electric-case-java-init)

And when you type the following in java-mode for example,

  public class test-class{
      public void test-method(void){

=electric-case= automatically converts it into :

  public class TestClass{
      public void testMethod(void){

Preconfigured settings for some other languages are also
provided. Try:

  (add-hook 'c-mode-hook electric-case-c-init)
  (add-hook 'ahk-mode-hook electric-case-ahk-init)
  (add-hook 'scala-mode-hook electric-case-scala-init)

For more informations, see Readme.org.
