const firebaseConfig = {
    apiKey: "AIzaSyDJMucqPnHrw584CYTFTzoiV8XpP5_UfoI",
    authDomain: "timetracker-d336f.firebaseapp.com",
    projectId: "timetracker-d336f",
    storageBucket: "timetracker-d336f.firebasestorage.app",
    messagingSenderId: "240633561676",
    appId: "1:240633561676:web:2d10cf5b21b24409e76ae9",
    measurementId: "G-NQ0C17144G"
};

firebase.initializeApp(firebaseConfig);

const auth = firebase.auth();
const db = firebase.firestore();

let isLoginMode = true;

auth.setPersistence(firebase.auth.Auth.Persistence.LOCAL);

auth.onAuthStateChanged(async (user) => {
    if (user) {
        console.log("Login detected for:", user.email);

        let userData = {
            uid: user.uid,
            email: user.email,
            firstName: "User",
            lastName: ""
        };

        try {
            // Try to get extra info, but don't let it stop the login if it fails
            const snap = await db.collection("users").doc(user.uid).get();
            if (snap.exists) {
                const data = snap.data();
                userData.firstName = data.firstName || "Developer";
                userData.lastName = data.lastName || "";
            }
        } catch (error) {
            console.warn("Could not fetch profile, proceeding anyway:", error);
        }

        // 🚀 THIS IS THE KEY: Sending the signal to main.js
        if (window.electronAPI && window.electronAPI.authSuccess) {
            window.electronAPI.authSuccess(userData);
        } else {
            console.error("electronAPI not found! Check your preload.js");
        }
    }
});

window.toggleMode = function () {
    isLoginMode = !isLoginMode;
    document.getElementById("auth-title").innerText = isLoginMode ? "Welcome Back" : "Create Account";
    document.getElementById("auth-btn").innerText = isLoginMode ? "Login" : "Sign Up";
    document.getElementById("signup-fields").style.display = isLoginMode ? "none" : "block";
};

window.handleAuth = async function () {
    // 🛑 FIXED: Changed variable names to avoid conflict with element IDs
    const emailVal = document.getElementById("email").value.trim();
    const passVal = document.getElementById("pass").value;

    if (!emailVal || !passVal) {
        throw new Error("Please enter email and password");
    }

    if (isLoginMode) {
        return auth.signInWithEmailAndPassword(emailVal, passVal);
    } else {
        const firstName = document.getElementById("fname").value;
        const lastName = document.getElementById("lname").value;

        const res = await auth.createUserWithEmailAndPassword(emailVal, passVal);
        await db.collection("users").doc(res.user.uid).set({
            firstName: firstName,
            lastName: lastName,
            email: emailVal
        });
        return res;
    }
};