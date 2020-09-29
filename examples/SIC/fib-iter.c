int main() {
  int n = 10;
  int prev1 = 1;
  int prev2 = 1;
  int result = 1;
  for (int i = 3; i <= n; i++) {
    result = prev1 + prev2;
    int tmp = prev1;
    prev1 = result;
    prev2 = tmp;
  }
  return result;
}