import java.rmi.RemoteException;
import com.sas.metadata.remote.AssociationList;
import com.sas.metadata.remote.CMetadata;
import com.sas.metadata.remote.Person;
import com.sas.metadata.remote.MdException;
import com.sas.metadata.remote.MdFactory;
import com.sas.metadata.remote.MdFactoryImpl;
import com.sas.metadata.remote.MdOMIUtil;
import com.sas.metadata.remote.MdOMRConnection;
import com.sas.metadata.remote.MdObjectStore;
import com.sas.metadata.remote.MetadataObjects;
import com.sas.metadata.remote.PrimaryType;
import com.sas.metadata.remote.Tree;
import com.sas.meta.SASOMI.ISecurity_1_1;
import com.sas.iom.SASIOMDefs.VariableArray2dOfStringHolder;

public class InternalUserPwdSetter {
	String serverName = null;
	String serverPort = null;
	String serverUser = null;
	String serverPass = null;

	public InternalUserPwdSetter(String name, String port, String user, String pass) {
		serverName = name;
		serverPort = port;
		serverUser = user;
		serverPass = pass;
	}

    public void setPassword(String IdentityName, String IdentityPassword) {
		MdFactoryImpl factory = new MdFactoryImpl(false);
		MdOMRConnection connection = factory.getConnection();
		connection.makeOMRConnection(serverName, serverPort, serverUser, serverPass);
		
		ISecurity_1_1 iSecurity = connection.MakeISecurityConnection();
		
		//
		// This block obtains the person metadata ID that is needed to change the password
		//
		// Defines the GetIdentityInfo ReturnUnrestrictedSource option.
		final String[][] options = [["ReturnUnrestrictedSource",""]] as String;
		
		// Defines a stringholder for the info output parameter.
		VariableArray2dOfStringHolder info = new VariableArray2dOfStringHolder();
		
		// Issues the GetInfo method for the provided iSecurity connection user.
		iSecurity.GetInfo("GetIdentityInfo", "Person:" + IdentityName, options, info);
		
		String[][] returnArray = info.value;
		
		String personMetaID = new String();
		for (int i = 0; i < returnArray.length; i++ )
		{
			if (returnArray[i][0].compareTo("IdentityObjectID") == 0) {
				personMetaID = returnArray[i][1];
			}
		}

		MdObjectStore objectStore = factory.createObjectStore();
		Person person = (Person)factory.createComplexMetadataObject(objectStore, IdentityName, MetadataObjects.PERSON, personMetaID);
		iSecurity.SetInternalPassword(IdentityName, IdentityPassword);
		person.updateMetadataAll();
		
		System.out.println("Password has been changed.");
	}
}