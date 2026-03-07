import { useEffect, useState } from "react";

const ConsentTimer = ({ expiresAt }) => {

  const [timeLeft, setTimeLeft] = useState("");

  useEffect(() => {

    if(!expiresAt) return

    const interval = setInterval(() => {

      const diff = new Date(expiresAt) - new Date();

      const minutes = Math.floor(diff / 60000);

      setTimeLeft(`${minutes} minutes remaining`);

    }, 1000);

    return () => clearInterval(interval);

  }, [expiresAt]);

  return <div><strong>Access:</strong> {timeLeft}</div>;
};

export default ConsentTimer;