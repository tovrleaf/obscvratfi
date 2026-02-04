        // Text toggle every 6 seconds
        const harshNoise = document.querySelector(".harsh-noise");
        const caustic = document.querySelector(".caustic");
        const hemorrhaging = document.querySelector(".hemorrhaging");
        const audioRitual = document.querySelector(".audio-ritual");
        const analogFilth = document.querySelector(".analog-filth");
        
        // Only run if elements exist
        if (harshNoise && caustic && hemorrhaging && audioRitual && analogFilth) {
            let currentState = 1;

            function toggleTextState() {
                if (currentState === 1) {
                    // Hide state 1, show state 2
                    harshNoise.classList.add("hidden");
                    audioRitual.classList.add("hidden");
                    caustic.classList.remove("hidden");
                    hemorrhaging.classList.remove("hidden");
                    analogFilth.classList.remove("hidden");
                    currentState = 2;
                } else {
                    // Hide state 2, show state 1
                    harshNoise.classList.remove("hidden");
                    audioRitual.classList.remove("hidden");
                    caustic.classList.add("hidden");
                    hemorrhaging.classList.add("hidden");
                    analogFilth.classList.add("hidden");
                    currentState = 1;
                }
            }

            // Toggle states every 6 seconds
            setInterval(toggleTextState, 6000);
        }
