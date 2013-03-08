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

import junit.framework.TestSuite;

import org.apache.log4j.Logger;

/**
 * DOCUMENT ME! AllFuncTests.java
 * 
 * @author Joni Hahkala <joni.hahkala@cern.ch> Created on October 1, 2002, 4:52 PM
 */
public class AllFuncTests extends TestSuite {
	/** DOCUMENT ME! */
	static Logger s_logger = Logger.getLogger(AllFuncTests.class.getPackage().getName());

	/**
	 * DOCUMENT ME!
	 * 
	 * @param args DOCUMENT ME!
	 */
	public static void main(final String[] args) {
		junit.textui.TestRunner.run(suite());
		AllTests.main(args);
	}

	/**
	 * DOCUMENT ME!
	 * 
	 * @return DOCUMENT ME!
	 */
	public static TestSuite suite() {
		TestSuite suite = new TestSuite("All trustmanager functional tests");

		// $JUnit-BEGIN$

		// $JUnit-END$
		return suite;
	}
}
