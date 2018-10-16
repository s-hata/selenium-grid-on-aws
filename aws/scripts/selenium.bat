set "JAVA_OPTS=-Dwebdriver.chrome.driver=C:\selenium\chromedriver.exe -Dwebdriver.gecko.driver=C:\selenium\geckodriver.exe -Dwebdriver.ie.driver=C:\selenium\IEDriverServer.exe"
java %JAVA_OPTS% -jar C:\selenium\selenium-server-standalone.jar -role node -nodeConfig C:\selenium\node.json
