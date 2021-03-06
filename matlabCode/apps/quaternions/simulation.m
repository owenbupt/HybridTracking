function result = simulation( x,eqsystem )
syms rx ry rz tx ty tz;

% Substitutes the eqsystem for the prepared variables
a = max(abs(double(subs(eqsystem, [rx; ry; rz; tx; ty; tz], x))));
result = a;
end

