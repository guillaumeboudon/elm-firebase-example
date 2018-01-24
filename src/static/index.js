require('./index.html')
require('../assets/styles/index.scss')

// elm application
var Elm = require('../elm/Main.elm')
var app = Elm.Main.embed(document.getElementById('main'))

// Firebase init
import * as firebase from 'firebase'

firebase.initializeApp({
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: process.env.FIREBASE_AUTH_DOMAIN,
  databaseURL: process.env.FIREBASE_DATABASE_URL,
  projectId: process.env.FIREBASE_PROJECT_ID,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID
})

// Firebase authentication
let auth = firebase.auth()

app.ports.authSignUp.subscribe(function(data) {
  auth.createUserWithEmailAndPassword(data.email, data.password)
})

app.ports.authLogIn.subscribe(function(data) {
  return auth.signInWithEmailAndPassword(data.email, data.password)
})

app.ports.authLogOut.subscribe(function(data) {
  return auth.signOut()
})

auth.onAuthStateChanged(function (user) {
  if (user) {
    app.ports.authLoggedIn.send({
      email: user.email,
      uid: user.uid
    })
  } else {
    app.ports.authLoggedOut.send("")
  }
})


// Firebase database
let database = firebase.database()

app.ports.databaseFetchData.subscribe(function(uid) {
  database.ref('/users/' + uid).once('value')
    .then(function(snapshot) {
      var receivedData = snapshot.val() || "empty"
      app.ports.databaseReceiveData.send(receivedData)
    })
})
