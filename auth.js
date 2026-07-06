let isLoginMode = true;

window.toggleMode = function () {
    isLoginMode = !isLoginMode;
    document.getElementById("auth-title").innerText = isLoginMode ? "Welcome Back" : "Create Account";
    document.getElementById("auth-btn").innerText = isLoginMode ? "Login" : "Sign Up";
    document.getElementById("signup-fields").style.display = isLoginMode ? "none" : "block";
};

window.handleAuth = async function () {
    const emailVal = document.getElementById("email").value.trim();
    const passVal = document.getElementById("pass").value;

    if (!emailVal || !passVal) {
        throw new Error("Please enter email and password");
    }

    let res;
    if (isLoginMode) {
        res = await window.electronAPI.invoke("auth-login", emailVal, passVal);
    } else {
        const firstName = document.getElementById("fname").value;
        const lastName = document.getElementById("lname").value;
        res = await window.electronAPI.invoke("auth-signup", emailVal, passVal, firstName, lastName);
    }

    if (!res.success) {
        throw new Error(res.error || "Authentication failed");
    }

    if (window.electronAPI && window.electronAPI.authSuccess) {
        window.electronAPI.authSuccess(res.userData);
    }
};