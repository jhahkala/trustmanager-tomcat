/*
 * Copyright (c) Members of the EGEE Collaboration. 2004. See
 * http://www.eu-egee.org/partners/ for details on the copyright holders.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */

package org.glite.security.trustmanager;

import junit.framework.TestCase;

import org.apache.log4j.BasicConfigurator;
import org.apache.log4j.ConsoleAppender;
import org.apache.log4j.Layout;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.apache.log4j.PatternLayout;
import org.apache.log4j.PropertyConfigurator;
import org.apache.log4j.helpers.NullEnumeration;

/**
 * The base class for the security tests.
 * 
 * @author Joni Hahkala
 */
public class TestBase extends TestCase {
	/** The default base directory for security tests. */
	public static final String GLITE_SECURITY_HOME = "..";

	/** the system variable to use to get the security tests base dir. */
	public static final String GLITE_SECURITY_HOME_STRING = "gliteSecurity.home";

	/** the default stage directory. */
	public static final String GLITE_SECURITY_STAGE_DEFAULT = "../stage";

	/** the system variable to read for the stage directory */
	public static final String GLITE_SECURITY_STAGE_STRING = "stage.abs.dir";

	/** the logging facility. */
	static final Logger LOGGER = Logger.getLogger(TestBase.class.getName());

	/** the base directory for security tests. */
	public String m_gliteSecurityHome;

	/** the base directory for test certificates. */
	public String m_certHome;

	/** the stage directory. */
	public String m_stageDir;

	/**
	 * Creates a new TestBase object.
	 * 
	 * @param arg0 not used.
	 */
	public TestBase(String arg0) {
		super(arg0);

		m_gliteSecurityHome = initEnv();
		m_stageDir = initStage();
		m_certHome = m_stageDir + "/share/test/certificates";

		// if no configuration given and logging is not setup, output to console and set level to WARN
		final Layout lay = new PatternLayout("%-5p %d{dd MMM yyyy HH:mm:ss,SSS} [%t] %c %x: %m%n");

		if (LOGGER.getAllAppenders() instanceof NullEnumeration) {
			BasicConfigurator.configure(new ConsoleAppender(lay));

			Logger parent = Logger.getLogger("org.glite.security");
			parent.setLevel(Level.WARN);
		}
	}

	/**
	 * Initializes the security tests base directory.
	 * 
	 * @return the base directory.
	 */
	public static String initEnv() {
		String gliteSecurityHome = System.getProperty(GLITE_SECURITY_HOME_STRING, GLITE_SECURITY_HOME);
		System.out.println("TM:got home: " + System.getProperty(GLITE_SECURITY_HOME_STRING));
		PropertyConfigurator.configure(gliteSecurityHome
				+ "/org.glite.security.trustmanager/test/conf/log4j.properties");

		return gliteSecurityHome;
	}

	/**
	 * Initializes the stage directory value.
	 * 
	 * @return the stage directory.
	 */
	public static String initStage() {
		String stageDir = System.getProperty(GLITE_SECURITY_STAGE_STRING, GLITE_SECURITY_STAGE_DEFAULT);
		System.out.println("TM:got stage: " + System.getProperty(GLITE_SECURITY_STAGE_STRING));

		return stageDir;
	}
}
