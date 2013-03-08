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

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.SocketException;
import java.security.GeneralSecurityException;
import java.util.Properties;

import javax.net.ssl.SSLException;
import javax.net.ssl.SSLServerSocket;
import javax.net.ssl.SSLSocket;

public class TestServerTest {

	/**
	 * @param args
	 */
	@SuppressWarnings("null")
    public static void main(String[] args) {

		//new VOMSValidator((X509Certificate[]) null);

		Properties serverProps = new Properties();
		System.out.println(args[0] + " " + args[1] + " " + args[2] + " " + args[3]);
		serverProps.setProperty(ContextWrapper.TRUSTSTORE_DIR, args[0]);
		// serverProps.setProperty(ContextWrapper.CA_FILES, args[0] + "\\*.0");
		// serverProps.setProperty(ContextWrapper.CRL_FILES, args[0] + "\\*.r0");
		serverProps.setProperty(ContextWrapper.CREDENTIALS_CERT_FILE, args[1]);
		serverProps.setProperty(ContextWrapper.CREDENTIALS_KEY_FILE, args[2]);
		serverProps.setProperty(ContextWrapper.LOG_CONF_FILE, args[3]);

		File file = new File(args[3]);

		System.out.println(file.getAbsolutePath());

		ContextWrapper wrapper = null;

		try {
			wrapper = new ContextWrapper(serverProps);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			System.exit(1);
		} catch (GeneralSecurityException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			System.exit(1);
		}

		SSLServerSocket serverSocket = null;

		try {
			serverSocket = (SSLServerSocket) wrapper.getServerSocketFactory().createServerSocket(5432);
		} catch (SSLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			System.exit(1);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			System.exit(1);
		}

		SSLSocket socket;
		boolean serving = true;

		// sSocket.setWantClientAuth(true);
		serverSocket.setNeedClientAuth(true);

		do {
			try {
				socket = (SSLSocket) serverSocket.accept();

				DataOutputStream out = new DataOutputStream(socket.getOutputStream());

				try {
					BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
					String buf;

					buf = in.readLine();
					System.out.println("Received: \"" + buf + "\"");
					if (!buf.equals("GET /index.html HTTP/1.1")) {
						throw new Exception("invalid input from client");
					}

					while (buf != null) {
						// System.out.println("> " + buf);
						if (buf.length() <= 0) {
							break;
						}

						buf = in.readLine();
					}

					try {
						out.writeBytes("HTTP/1.0 200 OK\r\n");
						out.writeBytes("Content-Type: text/html\r\n\r\n\r\n");
						out.writeBytes("TEST OK\r\n");
						out.flush();
						out.close();
					} catch (IOException ie) {
						ie.printStackTrace();
						throw ie;
					}
				} catch (Exception e) {
					// e.printStackTrace();
					// write out error response, if possible
					e.printStackTrace();
					out.writeBytes("HTTP/1.0 400 " + e.getMessage() + "\r\n");
					out.writeBytes("Content-Type: text/html\r\n\r\n\r\n");
					out.flush();
					out.close();
					throw e;
				}
			} catch (SocketException ex) {
				ex.printStackTrace();
				// eat exception
				System.out.println("Socket closed?: " + ex.getMessage());

				// ex.printStackTrace();
				serving = false;
			} catch (Exception ex) {
				ex.printStackTrace();
				// write error message if error was unexpected
				System.out.println("error writing response: " + ex.getMessage());
				ex.printStackTrace();
			}
		} while (serving == true);

	}

}
