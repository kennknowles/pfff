<?php

// C++ is famous for forcing people to add space between > to
// avoid ambiguities with the '>>' operator as in
// vector<vector<int> >. 
// sphp currently uses some parsing hacks to allow the vector<vector<int>>
// syntax

function foo(A<A<int>> $x): ?int {
  return null; 
};