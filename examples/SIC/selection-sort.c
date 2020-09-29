#define LEN 10
int arr[] = {7, 8, 9, 1, 2, 3, 5, 4, 0, 6};
void swap(int *a, int *b) {
  int temp = *a;
  *a = *b;
  *b = temp;
}
int main() {
  for (int i = 0; i < LEN; i++) {
    for (int j = i + 1; j < LEN; j++) {
      if (arr[i] > arr[j]) {
        int *a = &arr[i];
        int *b = &arr[j];
        swap(a, b);
      }
    }
  }
  return arr[LEN - 1];
}