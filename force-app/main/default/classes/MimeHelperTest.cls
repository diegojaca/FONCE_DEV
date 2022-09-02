@IsTest
private class MimeHelperTest {

  @IsTest
  private static void testGetExtension() {
    System.assertEquals('png', MimeHelper.getExtension('image/png'));
  }

}