import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'dart:io';
import 'package:oauth2/oauth2.dart' as oauth2;

// These URLs are endpoints that are provided by the authorization
// server. They're usually included in the server's documentation of its
// OAuth2 API.
final authorizationEndpoint =
Uri.parse("http://example.com/oauth2/authorization");
final tokenEndpoint =
Uri.parse("http://example.com/oauth2/token");

// The authorization server will issue each client a separate client
// identifier and secret, which allows the server to tell which client
// is accessing it. Some servers may also have an anonymous
// identifier/secret pair that any client may use.
//
// Note that clients whose source code or binary executable is readily
// available may not be able to make sure the client secret is kept a
// secret. This is fine; OAuth2 servers generally won't rely on knowing
// with certainty that a client is who it claims to be.
final identifier = "ojqqd5c5pzkcckscw8g48owgwg4g8ogk8o840woo8cog0g8o0";
final secret = "1wu4qg4u5u2sc0ww8c0gkosc4gk04ksk0ko4g8cscw0ww8wgkw";

// This is a URL on your application's server. The authorization server
// will redirect the resource owner here once they've authorized the
// client. The redirection will include the authorization code in the
// query parameters.
final redirectUrl = Uri.parse("http://127.0.0.1:8000/");

// A file in which the users credentials are stored persistently. If the server
// issues a refresh token allowing the client to refresh outdated credentials,
// these may be valid indefinitely, meaning the user never has to
// re-authenticate.
final credentialsFile = new File("~/.myapp/credentials.json");

// Either load an OAuth2 client from saved credentials or authenticate a new
// one.
Future<oauth2.Client> getClient() async {
  var exists = await credentialsFile.exists();

  // If the OAuth2 credentials have already been saved from a previous run, we
  // just want to reload them.
  if (exists) {
    var credentials = new oauth2.Credentials.fromJson(
        await credentialsFile.readAsString());
    return new oauth2.Client(credentials,
        identifier: identifier, secret: secret);
  }

  // If we don't have OAuth2 credentials yet, we need to get the resource owner
  // to authorize us. We're assuming here that we're a command-line application.
  var grant = new oauth2.AuthorizationCodeGrant(
      identifier, authorizationEndpoint, tokenEndpoint,
      secret: secret);

  // Redirect the resource owner to the authorization URL. This will be a URL on
  // the authorization server (authorizationEndpoint with some additional query
  // parameters). Once the resource owner has authorized, they'll be redirected
  // to `redirectUrl` with an authorization code.
  //
  // `redirect` is an imaginary function that redirects the resource
  // owner's browser.
  //await redirect(grant.getAuthorizationUrl(redirectUrl));
  print(grant.getAuthorizationUrl(redirectUrl));

  // Another imaginary function that listens for a request to `redirectUrl`.
  //var request = await listen(redirectUrl);

  var request = new Map<String, String>();

  // Once the user is redirected to `redirectUrl`, pass the query parameters to
  // the AuthorizationCodeGrant. It will validate them and extract the
  // authorization code to create a new Client.
  //return await grant.handleAuthorizationResponse(request.uri.queryParameters);
  return await grant.handleAuthorizationResponse(request);
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Test(title: 'Flutter Demo Home Page', message: "Welcome to test!"),
      routes:  <String, WidgetBuilder> {
        "/welcome":(BuildContext context) => Test(title: 'Flutter Demo Home Page', message: "Welcome to test!"),
        //"/signin": (BuildContext context) => new SignIn(),
        //"/personal_data": (BuildContext context) => new PersonalData(),
        "/click": (BuildContext context) => MyHomePage(title: "Home page!"),
      },
    );
  }
}

class Test extends StatelessWidget {
  Test({Key key, this.title, this.message }) : super(key: key);
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              message,
              style: Theme.of(context).textTheme.display1,
            ),
            RaisedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/click');
              },
              child: Text('Go to click!'),
            ),
          ],
        ),
      ),
    );
  }

}


class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _result = "";
  var stateClient;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  final _userName = TextEditingController(text:"");
  final _password = TextEditingController(text:"");

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    _userName.dispose();
    _password.dispose();
    super.dispose();
  }

  _test() async {
    var client = await getClient();

    var result = client.read("http://127.0.0.1:8000/api/users");

    await credentialsFile.writeAsString(client.credentials.toJson());

    print(result);
  }

  void _getUsers() async {
    var result = "";
    if(stateClient == null) {
      result = "Please log in";
    } else {
      result = await stateClient.read("http://127.0.0.1:8000/api/users");
    }
    setState(() {
      _result = result;
    });
  }

  void _clearClient() {
    if(stateClient != null) {
      stateClient.close();
      stateClient = null;
    }
    setState(() {
      _result = "Token was cleared";
    });
  }

  void _login() async {

    _clearClient();

    final authorizationEndpoint =
      Uri.parse("http://127.0.0.1:8000/oauth/v2/token");

    final identifier = "1_ojqqd5c5pzkcckscw8g48owgwg4g8ogk8o840woo8cog0g8o0";
    final secret = "1wu4qg4u5u2sc0ww8c0gkosc4gk04ksk0ko4g8cscw0ww8wgkw";
    var result = "";
    try {
      var client = await oauth2.resourceOwnerPasswordGrant(
          authorizationEndpoint, _userName.text, _password.text,
          identifier: identifier, secret: secret);
      stateClient = client;
      result = "Success!";
    } catch(ex) {
      result = ex.toString();
      stateClient = null;
    }
    setState(() {
      _result = result;
    });

  }

  @override
  Widget build(BuildContext context) {

    if (Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              MaterialButton(onPressed: _incrementCounter, color: Colors.green[100],
                  child: Text('Click!')),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.display1,
              ),

            ],
          ),
        ),
      );
    } else if (Platform.isIOS) {
      return new Scaffold(
        body: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Buttons'),
          previousPageTitle: 'Cupertino',
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              //CupertinoButton(onPressed: _incrementCounter, child:Text('Click!'), color: Colors.green[100]),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _userName,
                  decoration: new InputDecoration(
                    hintText: 'Type something',
                  ),
                ),

              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _password,
                  decoration: new InputDecoration(
                    hintText: 'Type something',
                  ),
                ),
              ),
              CupertinoButton(onPressed: _login, child:Text('Login!'), color: Colors.green[100]),
              CupertinoButton(onPressed: _clearClient, child:Text('Clear token!'), color: Colors.red[100]),
              CupertinoButton(onPressed: _getUsers, child:Text('Api Test!'), color: Colors.blue[100]),
              Text(
                '$_result',
                style: Theme.of(context).textTheme.body1,
              ),

            ],
          ),
        ),
      ),
      );
    }

    return Text(
      'Something is very wrong',
      style: Theme.of(context).textTheme.display1,
    );

  }
}
