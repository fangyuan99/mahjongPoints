<script setup>
import { reactive, onMounted, watch } from "vue";
import {
  useDark,
  useToggle,
  useDocumentVisibility,
  useStorage,
} from "@vueuse/core";
import axios from "axios";
import dayjs from "dayjs";
const isDark = useDark();
const toggleDark = useToggle(isDark);

const url = import.meta.env.VITE_BASE_URL;
let mahjongData = reactive({
  data: [],
  activeName: "",
  isLoading: false,
});

let latelyData = reactive({
  data: [],
  showMore: false,
  showDetail: false,
  detailData: {},
});

const roomNumber = useStorage("roomNumber", "000000");
//获取房间号列表
const getRoomNumberList = async () => {
  let data = {
    type: "getRoomNumberList",
  };
  try {
    let res = await axios.post(url, data);
    roomNumberList = eval(res.data["roomNumberList"]);
  } catch (e) {
    ElMessage({
      message: "获取房间号列表失败，请检查网络连接" + e,
      type: "error",
    });
  }
};
let roomNumberList = reactive([]);

const getDateByIndex = (index) => {
  return dayjs(new Date(latelyData.data[index].date)).format(
    "YYYY-MM-DD HH:mm"
  );
};

const getDateByTime = (time) => {
  return dayjs(new Date(time)).format("YYYY-MM-DD HH:mm");
};

let sumData = reactive({
  showDetail: false,
  detailData: {},
});

//上传云端数据
const uploadData = async () => {
  let data = {
    mahjongData: mahjongData.data,
    latelyData: latelyData.data,
    type: "upload",
    roomNumber: roomNumber.value,
  };
  try {
    let res = await axios.post(url, data);
  } catch (e) {
    ElMessage({
      message: "上传数据失败，请检查网络连接" + e,
      type: "error",
    });
  }
};

const switchRooms = async (number) => {
  if (
    Number(number) < 0 ||
    Number(number) > 999999 ||
    isNaN(Number(number)) ||
    (number + "").length !== 6
  ) {
    ElMessage({
      message: `房间号${number}格式错误，请检查是否为6位数字`,
      type: "error",
    });
    return;
  }
  if (roomNumber === number) {
    ElMessage({
      message: "已经在该房间了，无需切换",
      type: "success",
    });
  } else {
    roomNumber.value = number;
    let res = await downloadData();
    if (res !== "error") {
      ElMessage({
        message: `切换${number}房间成功`,
        type: "success",
      });
      getRoomNumberList();

      if (mahjongData.data.length !== 0) {
        mahjongData.activeName = "";
      } else {
        ElMessage({
          message: `房间为空请先添加玩家`,
          type: "warning",
        });
      }
    }
    // location.reload()
  }
};

const createRoom = async () => {
  //获取用户输入的房间号，发送给后端
  ElMessageBox.prompt("请输入房间号", "创建房间", {
    confirmButtonText: "确定",
    cancelButtonText: "取消",
    inputPattern: /^[0-9]{6}$/,
    inputErrorMessage: "房间号为6位数字",
  })
    .then(async ({ value }) => {
      let data = {
        type: "createRoom",
        roomNumber: value,
      };
      try {
        let res = await axios.post(url, data);
        if (res.data === "success") {
          ElMessage({
            message: `创建${value}房间成功`,
            type: "success",
          });
          // 跳转到新建的房间
          switchRooms(value);
        } else {
          ElMessage({
            message: `创建${value}房间失败`,
            type: "error",
          });
        }
      } catch (e) {
        ElMessage({
          message: "创建房间失败，请检查网络连接" + e,
          type: "error",
        });
      }
    })
    .catch(() => {});
};

const deleteRoom = async () => {
  //删除roomNumber房间
  ElMessageBox.confirm(
    `此操作将永久删除${roomNumber.value}, 是否继续?`,
    "提示",
    {
      confirmButtonText: "确定",
      cancelButtonText: "取消",
      type: "warning",
    }
  )
    .then(async () => {
      let data = {
        type: "deleteRoom",
        roomNumber: roomNumber.value,
      };
      try {
        let res = await axios.post(url, data);
        if (res.data === "success") {
          ElMessage({
            message: `删除${roomNumber.value}房间成功`,
            type: "success",
          });
          // 切换到默认房间
          roomNumber.value = "000000";
          switchRooms(roomNumber.value);
        } else {
          ElMessage({
            message: `删除${roomNumber.value}房间失败`,
            type: "error",
          });
        }
      } catch (e) {
        ElMessage({
          message: "删除房间失败，请检查网络连接" + e,
          type: "error",
        });
      }
    })
    .catch(() => {});
};

//下载云端数据
const downloadData = async () => {
  let data = {
    type: "download",
    roomNumber: roomNumber.value,
  };
  try {
    let res = await axios.post(url, data);
    let cloudData = res.data;
    // 页面显示加载中
    // 若本地数据和云端数据不一致，则更新本地数据
    if (
      JSON.stringify(cloudData.mahjongData) != JSON.stringify(mahjongData.data)
    ) {
      mahjongData.data = cloudData.mahjongData;
      // console.log("mahjongData云端数据更新成功");
    }
    if (
      JSON.stringify(cloudData.latelyData) != JSON.stringify(latelyData.data)
    ) {
      latelyData.data = cloudData.latelyData;
      // console.log("mahjongData云端数据更新成功");
    }
    return cloudData;
  } catch (e) {
    ElMessage({
      message: "下载数据失败，请检查网络连接" + e,
      type: "error",
    });
    return "error";
  }
};

const filterMethod = () => {
  roomNumberList = roomNumberList.filter((item) => {
    //保留item为6位数字组成的字符串的项
    return !isNaN(Number(item)) && (item + "").length === 6;
  });
};

//更新数据
const updateData = () => {
  //只要thisMoney有值，就返回，否则downloadData
  for (let i = 0; i < mahjongData.data.length; i++) {
    if (mahjongData.data[i].thisMoney !== "") {
      ElMessage({
        message: "当前还有未结算的数据，请结算后再更新",
        type: "warning",
      });
      return;
    }
  }
  downloadData();
};

//清空云端数据
const clearCloudData = async () => {
  let data = {
    type: "clear",
    roomNumber: roomNumber.value,
  };
  let res = await axios.post(url, data);
  downloadData();
};

const showCol = (name) => {
  document.querySelector(".operation").style.zIndex = -100;
  if (name === "") {
    setTimeout(() => {
      document.querySelector(".operation").style.zIndex = 100;
    }, 300);
  }
};

onMounted(() => {
  mahjongData.isLoading = true;
  downloadData();
  mahjongData.isLoading = false;
  getRoomNumberList();

  //给最新的版本号添加双击事件，双击后，清空localStorage
  let version = document.querySelector(".version");
  clickEvent(version, null, cleanCache);
});

const visibility = useDocumentVisibility();
// 当页面可见时，从云端下载数据
watch(visibility, (val) => {
  if (val === "visible") {
    downloadData();
  }
});

const dealNum = (e, type) => {
  if (type === "blur") {
    document.querySelector(".operation").style.backgroundColor = "";
    document.querySelector(".operation").style.zIndex = -1000;
    return;
  }
  // 关闭折叠面板
  mahjongData.activeName = "";
  // console.log("dealNum");
  // 获取所有的输入框，遍历，若只有其他输入框都可以转为数字，则计算当前输入框的值，使得总和为0
  //设置z-index为100
  document.querySelector(".operation").style.zIndex = 100;
  // 背景颜色,rgb(181, 178, 178)，透明度为0.5

  document.querySelector(".operation").style.backgroundColor =
    "rgba(181, 178, 178, 0.19)";

  let allInput = document.querySelectorAll(".thisMoney input");
  let allInputArr = Array.from(allInput);
  let numberOfNums = 0;
  allInput.forEach((item) => {
    if (item.value === "" || isNaN(item.value) || item === e.target) {
      return false;
    }
    numberOfNums++;
  });
  // console.log("numberOfNums", numberOfNums);
  if (numberOfNums < allInput.length - 1) {
    return;
  }
  let sum = 0;
  allInputArr.forEach((item) => {
    if (item === e.target) {
      return;
    }
    if (item.value) {
      sum += Number(item.value);
    }
  });
  // console.log("sum", sum);
  mahjongData.data[allInputArr.indexOf(e.target)].thisMoney = -sum;
};

const addI = () => {
  //若没有玩家，提示先添加玩家
  if (mahjongData.data.length === 0) {
    ElMessage({
      message: "请先添加玩家",
      type: "warning",
    });
    return;
  }
  // console.log("addI");
  // 获取所有的输入框，遍历，若只有其他输入框都可以转为数字，则计算当前输入框的值，使得总和为0
  let allInput = document.querySelectorAll(".thisMoney input");
  let allInputArr = Array.from(allInput);
  let flag = true;
  // 若有输入框为空，则不计算
  allInput.forEach((item, index) => {
    if (item.value === "" || isNaN(item.value)) {
      ElMessage({
        message: `"${mahjongData.data[index].name}"数据填写有误`,
        type: "warning",
      });
      flag = false;
      return false;
    }
  });
  if (!flag) {
    return;
  }

  //若合计不为0，则不计算
  let sum = 0;
  allInputArr.forEach((item) => {
    sum += Number(item.value);
  });
  if (sum !== 0) {
    ElMessage({
      message: `合计不为0`,
      type: "warning",
    });
    flag = false;
  }
  if (!flag) {
    return;
  }
  for (let i = 0; i < allInputArr.length; i++) {
    mahjongData.data[i].thisMoney = Number(allInputArr[i].value);
    if (mahjongData.data[i].thisMoney >= 0) {
      mahjongData.data[i].numberOfVictories++;
      mahjongData.data[i].moneyOfVictories += mahjongData.data[i].thisMoney;
    } else {
      mahjongData.data[i].numberOfDefeats++;
      mahjongData.data[i].moneyOfDefeats += mahjongData.data[i].thisMoney;
    }
    mahjongData.data[i].moneyOfTotal += mahjongData.data[i].thisMoney;
    mahjongData.data[i].winningProbability = (
      mahjongData.data[i].numberOfVictories /
      (mahjongData.data[i].numberOfVictories +
        mahjongData.data[i].numberOfDefeats)
    ).toFixed(4);
    mahjongData.data[i].mahjongRecord.push(mahjongData.data[i].thisMoney);
    mahjongData.data[i].thisMoney = "";
  }
  uploadData();
  ElMessage({
    message: "添加成功",
    type: "success",
  });
};

const deleteI = (index) => {
  // console.log("deleteI");
  ElMessageBox.confirm("此操作将永久删除该记录, 是否继续?", "提示", {
    confirmButtonText: "确定",
    cancelButtonText: "取消",
    type: "warning",
  })
    .then(() => {
      //
      console.log("删除");
      mahjongData.data.forEach((item) => {
        if (item.mahjongRecord[index] >= 0) {
          item.numberOfVictories--;
          item.moneyOfVictories -= item.mahjongRecord[index];
        } else {
          item.numberOfDefeats--;
          item.moneyOfDefeats -= item.mahjongRecord[index];
        }
        item.moneyOfTotal -= item.mahjongRecord[index];
        item.winningProbability = (
          item.numberOfVictories /
          (item.numberOfVictories + item.numberOfDefeats)
        ).toFixed(4);
        item.mahjongRecord.splice(index, 1);
      });
      uploadData();
    })
    .catch(() => {
      // console.log("取消");
    });
};

const deleteH = (data) => {
  //找到对应的数据，删除

  let index = latelyData.data.findIndex((item) => {
    return item.mahjongData === data;
  });
  console.log("index", index);
  console.log("data", data);
  console.log("latelyData.data", latelyData.data);
  ElMessageBox.confirm("此操作将永久删除该记录, 是否继续?", "提示", {
    confirmButtonText: "确定",
    cancelButtonText: "取消",
    type: "warning",
  })
    .then(() => {
      latelyData.data.splice(index, 1);
      uploadData();
      //关闭dialog
      latelyData.showDetail = false;
      ElMessage({
        message: "删除成功",
        type: "success",
      });
    })
    .catch(() => {
      // console.log("取消");
    });
};

const showDetail = (index) => {
  latelyData.detailData = latelyData.data[index].mahjongData;
  //添加一个属性，记录当前的index
  latelyData.detailData.index = index;
  latelyData.showDetail = true;
};

const showSummaryInformation = (item) => {
  let sum = {
    id: item.id,
    name: item.name,
    winningProbability: 0,
    numberOfVictories: 0,
    numberOfDefeats: 0,
    moneyOfVictories: 0,
    moneyOfDefeats: 0,
    moneyOfTotal: 0,
    mahjongRecord: [],
    thisMoney: "",
  };
  // 根据name找到对应的index
  let index = mahjongData.data.findIndex((item2) => {
    return item2.name === item.name;
  });
  latelyData.data.forEach((item2) => {
    // let index = Number(item.id);
    if (item2.mahjongData[index] === undefined) {
      return;
    }
    if (
      item2.mahjongData[index].id === item.id &&
      item2.mahjongData[index].name === item.name
    ) {
      sum.numberOfVictories += item2.mahjongData[index].numberOfVictories;
      sum.numberOfDefeats += item2.mahjongData[index].numberOfDefeats;
      sum.moneyOfVictories += item2.mahjongData[index].moneyOfVictories;
      sum.moneyOfDefeats += item2.mahjongData[index].moneyOfDefeats;
      sum.moneyOfTotal += item2.mahjongData[index].moneyOfTotal;
      //反向拼接数组
      sum.mahjongRecord = item2.mahjongData[index].mahjongRecord.concat(
        sum.mahjongRecord
      );
    }
  });
  // let index = Number(item.id);
  if (mahjongData.data[index] !== undefined) {
    sum.numberOfVictories += mahjongData.data[index].numberOfVictories;
    sum.numberOfDefeats += mahjongData.data[index].numberOfDefeats;
    sum.moneyOfVictories += mahjongData.data[index].moneyOfVictories;
    sum.moneyOfDefeats += mahjongData.data[index].moneyOfDefeats;
    sum.moneyOfTotal += mahjongData.data[index].moneyOfTotal;
    //正向拼接数组
    sum.mahjongRecord = sum.mahjongRecord.concat(
      mahjongData.data[index].mahjongRecord
    );
  }
  sum.winningProbability = (
    sum.numberOfVictories /
    (sum.numberOfVictories + sum.numberOfDefeats)
  ).toFixed(4);
  sumData.detailData = [sum];
  // console.log(sumData.detailData);
  sumData.showDetail = true;
  // latelyData.detailData = [sum];
  // latelyData.showDetail = true;
};

const clearI = () => {
  if (mahjongData.data.length === 0) {
    ElMessage({
      message: "请先添加玩家",
      type: "warning",
    });
    return;
  }
  // console.log("clearI");
  if (mahjongData.data[0].mahjongRecord.length === 0) {
    ElMessage({
      message: "无数据",
      type: "warning",
    });
    return;
  }
  ElMessageBox.confirm("此操作将永久删除所有记录, 是否继续?", "提示", {
    confirmButtonText: "确定",
    cancelButtonText: "取消",
    type: "warning",
  })
    .then(() => {
      //将当前记录加入历史记录，置于第一位
      latelyData.data.unshift({
        date: new Date().getTime(),
        mahjongData: JSON.parse(JSON.stringify(mahjongData.data)),
      });
      mahjongData.data.forEach((item) => {
        item.thisMoney = "";
        item.mahjongRecord = [];
        item.numberOfDefeats = 0;
        item.numberOfVictories = 0;
        item.moneyOfDefeats = 0;
        item.moneyOfVictories = 0;
        item.moneyOfTotal = 0;
        item.winningProbability = 0;
        item.highestSingleVictory = 0;
        item.highestSingleDefeat = 0;
      });
      uploadData();
    })
    .catch(() => {
      // console.log("取消删除");
    });
};

//定义一个方法，从数字变成百分比
const toPercent = (point) => {
  // 移动小数点
  let str = Number(point * 100).toFixed(2);
  // 加上%号
  str += "%";
  return str;
};

const getWinningProbability = (item) => {
  if (item.numberOfDefeats + item.numberOfVictories === 0) {
    return "0%";
  }
  return `${toPercent(item.winningProbability)}`;
};

const getWinningText = (item) => {
  if (item.numberOfDefeats + item.numberOfVictories === 0) {
    return "";
  }
  return `${item.numberOfVictories}胜${item.numberOfDefeats}跪`;
};

const getHighestSingleVictory = (item) => {
  let highestSingleVictory = 0;
  item.forEach((item) => {
    if (item > highestSingleVictory) {
      highestSingleVictory = item;
    }
  });
  return highestSingleVictory;
};

const getHighestSingleDefeat = (item) => {
  let highestSingleDefeat = 0;
  item.forEach((item) => {
    if (item < highestSingleDefeat) {
      highestSingleDefeat = item;
    }
  });
  return highestSingleDefeat;
};

//定义一个方法，计算是否连胜或者连跪
const getContestStreak = (item) => {
  if (item.mahjongRecord.length === 0) {
    return "";
  }
  //从后往前找，若当前值与前一个值正负相同，则继续往前找，若不同，则停止
  let streak = 1;
  let streakType = "";
  for (let i = item.mahjongRecord.length - 1; i > 0; i--) {
    if (item.mahjongRecord[i] * item.mahjongRecord[i - 1] > 0) {
      streak++;
    } else {
      break;
    }
  }

  if (streak > 0) {
    if (item.mahjongRecord[item.mahjongRecord.length - 1] > 0) {
      streakType = "胜";
    } else {
      streakType = "跪";
    }
  }
  return `${streak}${streakType}中`;
};

const getHighestVictoryStreak = (item) => {
  if (item.mahjongRecord.length === 0) {
    return "";
  }
  // 寻找连续的正数，返回最大值
  let streak = 0;
  let streakArr = [];
  for (let i = item.mahjongRecord.length - 1; i > 0; i--) {
    if (item.mahjongRecord[i] > 0) {
      streak++;
    } else {
      streakArr.push(streak);
      streak = 0;
    }
  }
  streakArr.push(streak);
  return Math.max(...streakArr);
};

const getHighestDefeatStreak = (item) => {
  if (item.mahjongRecord.length === 0) {
    return "";
  }
  // 寻找连续的负数，返回最大值
  let streak = 0;
  let streakArr = [];
  for (let i = item.mahjongRecord.length - 1; i > 0; i--) {
    if (item.mahjongRecord[i] < 0) {
      streak++;
    } else {
      streakArr.push(streak);
      streak = 0;
    }
  }
  streakArr.push(streak);
  return Math.max(...streakArr);
};

const totalColor = (num) => {
  if (num < 0) {
    return "color:red";
  }
  if (isDark.value) {
    return "color:white";
  }
  return "color:blue";
};

const isWx = () => {
  let ua = window.navigator.userAgent.toLowerCase();
  if (ua.match(/MicroMessenger/i) == "micromessenger") {
    return true;
  } else {
    return false;
  }
};

//给指定元素e绑定点击事件，a为单击事件，b为双击事件
const clickEvent = (e, a, b) => {
  var lastTouchEnd = 0;
  e.addEventListener(
    "click",
    function (event) {
      var now = new Date().getTime();
      if (now - lastTouchEnd <= 300) {
        clearTimeout(conter);
        if (b) b(event);
      } else {
        var conter = setTimeout(function () {
          if (a) a(event);
        }, 300);
      }
      lastTouchEnd = now;
    },
    false
  );
};

//定义一个方法，获取最新的版本号，并监听双击事件，清空全部数据并刷新页面
const cleanCache = () => {
  console.log("清空全部数据");
  ElMessageBox.confirm("此操作将清空全部数据, 是否继续?", "提示", {
    confirmButtonText: "确定",
    cancelButtonText: "取消",
    type: "warning",
  })
    .then(() => {
      localStorage.clear();
      clearCloudData();
    })
    .catch(() => {
      // console.log("取消");
    });
};

const exportData = () => {
  // console.log("导出数据");
  ElMessageBox.confirm("此操作将导出数据, 是否继续?", "提示", {
    confirmButtonText: "确定",
    cancelButtonText: "取消",
    type: "warning",
  })
    .then(() => {
      // console.log("导出数据");
      // console.log(latelyData.data);
      // console.log(JSON.stringify(latelyData.data));
      let data = `{"mahjongData":${JSON.stringify(
        mahjongData.data
      )},"latelyData":${JSON.stringify(latelyData.data)}}`;
      // 将data中的中文转换为unicode编码
      data = data.replace(/[\u4e00-\u9fa5]/g, function (match) {
        return "\\u" + ("000" + match.charCodeAt(0).toString(16)).slice(-4);
      });
      // 将数据写入剪贴板
      copyData(data);
      // navigator.clipboard.writeText(data);
      // console.log(data);
      let blob = new Blob([data], { type: "text/plain" });
      let a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = "userData.json";
      a.click();
    })
    .catch(() => {
      // console.log("取消");
    });
};

const addPlayer = () => {
  // 若已经有数据，则不允许添加玩家，提示需要先结余清空本圈数据
  if (mahjongData.data.length && mahjongData.data[0].mahjongRecord.length) {
    ElMessageBox.alert("请先结余清空本圈数据再添加新玩家", "提示", {
      confirmButtonText: "确定",
    });
    return;
  }
  // console.log("添加玩家");
  ElMessageBox.prompt("请输入玩家名称,支持批量输入,用逗号隔开", "添加提示", {
    confirmButtonText: "确定",
    cancelButtonText: "取消",
    inputPattern: /^[\u4e00-\u9fa5_a-zA-Z0-9,，]+$/,
    inputErrorMessage: "玩家名称只能包含中文、英文、数字和下划线",
  })
    .then(({ value }) => {
      // 把value中的，替换为英文逗号
      value = value.replace(/，/g, ",");

      // 根据逗号分割字符串为数组
      let value_list = value.split(",");
      //若数组里有重复的元素，则去重
      value_list = [...new Set(value_list)];
      for (value of value_list) {
        // 名称不能为空
        if (!value) {
          ElMessageBox.alert("玩家名称不能为空", "提示", {
            confirmButtonText: "确定",
          });
          continue;
        }
        // 名称不能重复
        if (mahjongData.data.some((item) => item.name === value)) {
          ElMessageBox.alert("玩家名称不能重复", "提示", {
            confirmButtonText: "确定",
          });
          continue;
        }
        let player = {
          id: mahjongData.data.length,
          name: value,
          winningProbability: 0,
          numberOfVictories: 0,
          numberOfDefeats: 0,
          moneyOfVictories: 0,
          moneyOfDefeats: 0,
          moneyOfTotal: 0,
          mahjongRecord: [],
          thisMoney: "",
        };
        mahjongData.data.push(player);
        uploadData();
        // console.log(latelyData.data);
      }
    })
    .catch(() => {
      // console.log("取消");
    });
};

const deletePlayer = () => {
  // 若已经有数据，则不允许删除玩家，提示需要先结余清空本圈数据
  if (mahjongData.data.length && mahjongData.data[0].mahjongRecord.length) {
    ElMessageBox.alert("请先结余清空本圈数据再删除玩家", "提示", {
      confirmButtonText: "确定",
    });
    return;
  }
  // console.log("删除玩家");
  ElMessageBox.prompt("请输入玩家名称,支持批量输入,用逗号隔开", "删除提示", {
    confirmButtonText: "确定",
    cancelButtonText: "取消",
    inputPattern: /^[\u4e00-\u9fa5_a-zA-Z0-9，,]+$/,
    inputErrorMessage: "玩家名称只能包含中文、英文、数字和下划线",
  })
    .then(({ value }) => {
      // 把value中的，替换为英文逗号
      value = value.replace(/，/g, ",");

      // 根据逗号分割字符串为数组
      let value_list = value.split(",");
      //若数组里有重复的元素，则去重
      value_list = [...new Set(value_list)];
      for (let j=0;j<value_list.length;j++) {
        // 确定删除该玩家吗
        ElMessageBox.confirm(`确定删除${value_list[j]}吗？`, "提示", {
          confirmButtonText: "确定",
          cancelButtonText: "取消",
          type: "warning",
        })
          .then(() => {
            // console.log("确定");
            // console.log(value_list[j]);
            let index = -1;
            for (let i = 0; i < mahjongData.data.length; i++) {
              if (mahjongData.data[i].name === value_list[j]) {
                index = i;
                break;
              }
            }
            if (index === -1) {
              ElMessageBox.alert("未找到该玩家", "提示", {
                confirmButtonText: "确定",
              });
              return;
            }
            mahjongData.data.splice(index, 1);
            uploadData();
          })
          .catch(() => {
            // console.log("取消");
          });
      }
    })
    .catch(() => {
      // console.log("取消");
    });
};

const mahjongRecord2String = (item, isComplete) => {
  // console.log(item);
  item = JSON.parse(JSON.stringify(item));
  let str = "";

  for (let i = 0; i < item.length; i++) {
    //去除item.name前面的空格
    // item[i].name = item[i].name.trim();
    str += item[i].name.trim().toString().padEnd(8, " ");
  }
  str += "\n";
  if (isComplete) {
    //添加本圈具体战绩
    for (let i = 0; i < item[0].mahjongRecord.length; i++) {
      for (let j = 0; j < item.length; j++) {
        //item[j].mahjongRecord[i]转成8个字符，不够的用空格补齐
        // 如果是正数，前面加个+号
        let num = item[j].mahjongRecord[i];
        if (num > 0) {
          num = "+" + num;
        } else if (num === 0) {
          num = " 0";
        }
        str += num.toString().padEnd(8, " ");
        +" ";
      }
      str += "\n";
    }
  }
  //添加合计
  str += "合计：".toString().padEnd(8, " ") + "\n";
  for (let i = 0; i < item.length; i++) {
    str += item[i].moneyOfTotal.toString().padEnd(8, " ") + " ";
  }
  //添加胜率
  str += "\n";
  str += "胜率：".toString().padEnd(8, " ") + "\n";
  for (let i = 0; i < item.length; i++) {
    str +=
      (getWinningProbability(item[i]) + " " + getWinningText(item[i]))
        .toString()
        .padEnd(8, " ") + " ";
  }

  //添加最高连胜和最高连跪
  str += "\n";
  str += "最高连胜：".toString().padEnd(8, " ") + "\n";
  for (let i = 0; i < item.length; i++) {
    str += getHighestVictoryStreak(item[i]).toString().padEnd(8, " ") + " ";
  }
  str += "\n";
  str += "最高连跪：".toString().padEnd(8, " ") + "\n";
  for (let i = 0; i < item.length; i++) {
    str += getHighestDefeatStreak(item[i]).toString().padEnd(8, " ") + " ";
  }
  str += "\n";
  //添加最高单局胜利和最高单局失败
  str += "最高单局胜利：".toString().padEnd(8, " ") + "\n";
  for (let i = 0; i < item.length; i++) {
    let highestSingleVictory = getHighestSingleVictory(item[i].mahjongRecord);
    if (highestSingleVictory > 0) {
      highestSingleVictory = "+" + highestSingleVictory;
    } else if (highestSingleVictory === 0) {
      highestSingleVictory = " 0";
    }
    str += highestSingleVictory.toString().padEnd(8, " ") + " ";
  }
  str += "\n";
  str += "最高单局失败：".toString().padEnd(8, " ") + "\n";
  for (let i = 0; i < item.length; i++) {
    let highestSingleDefeat = getHighestSingleDefeat(item[i].mahjongRecord);
    str += highestSingleDefeat.toString().padEnd(8, " ") + " ";
  }
  str += "\n";
  return str;
};

const copyData = (str) => {
  //创建一个textarea元素
  let textarea = document.createElement("textarea");
  //设置textarea的属性
  textarea.setAttribute("id", "textarea");
  textarea.setAttribute(
    "style",
    "position:fixed;top:0;left:0;width:0;height:0;"
  );
  //把内容放到textarea中
  textarea.value = str;
  //把textarea插入到body中
  document.body.appendChild(textarea);
  //选中textarea中的内容
  textarea.select();
  //复制
  document.execCommand("copy");
  //删除textarea
  document.body.removeChild(textarea);
  ElMessage.success("复制成功");
};
</script>

<template>
  <div class="toggle" v-if="false">
    <span @click.stop="toggleDark()">暗黑模式</span>
    <el-switch v-model="isDark" />
  </div>

  <div class="main">
    <h2 style="text-align: center; margin: 0" @click.stop="toggleDark()">
      麻将麻将计分!!!
    </h2>

    <div
      class="table"
      v-loading="mahjongData.isLoading"
      element-loading-background="rgba(122, 122, 122, 0.8)"
    >
      <table>
        <tbody>
          <th
            v-for="item in mahjongData.data"
            @click="showSummaryInformation(item)"
          >
            {{ item.name }} <br />
          </th>
          <tr style="margin-top: 20px">
            <td
              v-for="item in mahjongData.data"
              style="font-size: 14px; text-align: center"
            >
              胜率：{{ getWinningProbability(item) }}<br />{{
                getWinningText(item)
              }}
            </td>
          </tr>
          <tr style="margin-top: 20px">
            <td
              v-for="item in mahjongData.data"
              :style="
                'font-size: 14px; text-align: center;' +
                totalColor(-getContestStreak(item).indexOf('跪'))
              "
            >
              {{ getContestStreak(item) }}
            </td>
          </tr>
          <tr>
            <td v-for="item in mahjongData.data">
              <!-- 循环输出item中的每一项 -->
              <div
                type="primary"
                size="default"
                v-for="(m, index) in item.mahjongRecord"
              >
                <div class="card1" @click="deleteI(index)">
                  <code :style="totalColor(m)">
                    {{ m > 0 ? "+" : "" }}{{ m }}
                  </code>
                </div>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="operation">
      <tr class="total">
        <td
          v-for="item in mahjongData.data"
          @click="updateData"
          :style="
            totalColor(item.moneyOfTotal) + ';font-size: 30px;font-weight: bold'
          "
        >
          {{ item.moneyOfTotal > 0 ? "+" : "" }}{{ item.moneyOfTotal }}
        </td>
      </tr>

      <tr>
        <td
          v-for="item in mahjongData.data"
          :key="item.id"
          style="border: none"
        >
          <!-- 循环输出item中的每一项 -->
          <el-input
            v-model="item.thisMoney"
            @focus="dealNum($event, 'focus')"
            @blur="dealNum($event, 'blur')"
            class="thisMoney"
            type="number"
          />
        </td>
      </tr>

      <div class="info"></div>
      <div class="version">版本号：v3.3.3（2023年1月19日3:3:3）</div>

      <!-- <div class="version">版本号：v1.3.0（2022年12月22日13:05:49）</div> -->

      <!-- <div class="version">
        版本号：v1.2.0（2022年12月22日02:17:47）
      </div>
      <div class="version">版本号：v1.0.0（2022年12月21日22:53:20）</div> -->
      <div class="buttons">
        <el-button type="primary" size="large" @click="clearI"
          >结余清空</el-button
        >
        <el-button type="primary" size="large" @click="addI"
          >添加记录</el-button
        >
      </div>
    </div>
    <el-collapse
      v-model="mahjongData.activeName"
      @change="showCol(mahjongData.activeName)"
    >
      <el-collapse-item title="更多功能" name="2">
        <div class="moreF">
          <div class="switchRoom">
            <el-select
              v-model="roomNumber"
              placeholder="选择房间或者创建房间"
              style="width: 32%"
              type="number"
              @change="switchRooms(roomNumber)"
              @focus="getRoomNumberList"
            >
              <el-option
                v-for="item in roomNumberList"
                :key="item"
                :label="item"
                :value="item"
              />
            </el-select>
            <el-button text type="primary" size="large" @click="createRoom()"
              >创建房间</el-button
            >
            <el-button text type="danger" size="large" @click="deleteRoom()"
              >删除房间</el-button
            >

            <div>
              当前房间号<code
                @click="copyData(roomNumber)"
                class="roomNumber"
                >{{ roomNumber }}</code
              >，房间号为6位数字
            </div>
          </div>
          <!-- 添加一个导出数据按钮 -->
          <el-button
            text
            type="primary"
            size="large"
            @click="exportData"
            style="margin: 0 auto"
            >导出数据</el-button
          >
          <!-- 添加一个新增玩家按钮 -->
          <el-button
            text
            type="primary"
            size="large"
            @click="addPlayer"
            style="margin: 0 auto"
            >新增玩家</el-button
          >
          <!-- 添加一个删除玩家按钮 -->
          <el-button
            text
            type="danger"
            size="large"
            @click="deletePlayer"
            style="margin: 0 auto"
            >删除玩家</el-button
          >
        </div>
        <el-collapse-item title="最近记录" name="0">
          <div
            class="lately"
            v-for="(data, index) in latelyData.data"
            :key="data.date"
            @click="showDetail(index)"
          >
            <div class="latelyRecord" v-if="index <= 2 || latelyData.showMore">
              <div
                class="title"
                style="
                  display: flex;
                  justify-content: space-between;
                  align-items: center;
                "
              >
                <b>{{ getDateByTime(data.date) }}</b>
                <el-button
                  text
                  @click.stop="
                    copyData(
                      getDateByTime(data.date) +
                        '\n' +
                        mahjongRecord2String(
                          latelyData.data[index].mahjongData,
                          false
                        )
                    )
                  "
                  >复制不含战绩数据</el-button
                >
              </div>

              <div
                class="card2"
                v-for="item in data.mahjongData"
                :key="item.id"
              >
                <div></div>
                <code>
                  {{ item.name }}
                  胜率：{{ getWinningProbability(item) }}<br />{{
                    getWinningText(item)
                  }}<br />合计:
                  <span :style="totalColor(item.moneyOfTotal)"
                    >{{ item.moneyOfTotal > 0 ? "+" : ""
                    }}{{ item.moneyOfTotal }}</span
                  >
                </code>
              </div>
            </div>
          </div>
          <div class="showMore" v-if="latelyData.data.length > 3">
            <el-button
              text
              type="primary"
              @click="latelyData.showMore = !latelyData.showMore"
            >
              {{ latelyData.showMore ? "收起" : "展开" }}
              {{ latelyData.data.length - 3 }}
              条记录
            </el-button>
          </div>
        </el-collapse-item>
        <el-collapse-item title="使用说明" name="1">
          <code>
            <div>
              1.输入金额后，点击添加，即可添加一条记录（<b>输入到最后一个数据时，点击输入框即可自动计算</b>）
            </div>
            2.点击记录，即可删除该条记录<br />
            3.点击结余清空，即可保存本圈记录，并重新开始新一圈的记录<br />
            4.点击标题，即可切换暗黑/日间模式<br />
            5.双击版本号可以清除缓存，并刷新页面<br />
            6.点击玩家昵称，可以显示用户汇总数据<br />
            7.点击主页合计数据，可以用云端同步数据<br />
            <b
              >3.0.0 版本已经实现
              用户创建房间，房间内多人同时使用√（目前是所有人共用一个房间×）</b
            ><br />
            <div v-if="isWx()">
              微信端可以用浮窗模式，<b>点击右上角三个点，选择浮窗</b>，下次可以直接在主页左滑打开
            </div>
          </code>
        </el-collapse-item>
      </el-collapse-item>
    </el-collapse>
  </div>

  <el-dialog
    center
    v-model="latelyData.showDetail"
    title="详细数据"
    style="width: 90%; max-width: 450px"
  >
    <div style="display: flex; justify-content: space-between">
      <!-- 添加一个复制按钮 -->
      <el-button
        text
        type="success"
        size="default"
        @click="
          copyData(
            getDateByIndex(latelyData.detailData.index) +
              '\n' +
              mahjongRecord2String(latelyData.detailData, true)
          )
        "
        style="margin: 0 auto"
        >复制完整数据</el-button
      >
      <el-button
        text
        type="danger"
        size="default"
        @click="deleteH(latelyData.detailData)"
        style="margin: 0 auto"
        >删除数据</el-button
      >
    </div>
    <table>
      <tbody>
        <th v-for="item in latelyData.detailData">{{ item.name }} <br /></th>
        <tr style="margin-top: 20px">
          <td
            v-for="item in latelyData.detailData"
            style="font-size: 14px; text-align: center"
          >
            胜率：{{ getWinningProbability(item) }}<br />{{
              getWinningText(item)
            }}
          </td>
        </tr>
        <tr>
          <td v-for="item in latelyData.detailData" class="detailRecord">
            <!-- 循环输出item中的每一项 -->
            <div
              type="primary"
              size="default"
              v-for="(m, index) in item.mahjongRecord"
            >
              <div class="card1">
                <code :style="totalColor(m)">
                  {{ m > 0 ? "+" : "" }}{{ m }}
                </code>
              </div>
            </div>
          </td>
        </tr>

        <tr class="total">
          <td
            v-for="item in latelyData.detailData"
            :style="
              totalColor(item.moneyOfTotal) +
              ';font-size: 30px;font-weight: bold'
            "
          >
            <!-- 循环输出item中的每一项 -->
            {{ item.moneyOfTotal }}
          </td>
        </tr>
        <!-- 最高连胜 -->
        <tr>
          <td
            v-for="item in latelyData.detailData"
            style="font-size: 14px; text-align: center"
          >
            最高连胜：<br />{{ getHighestVictoryStreak(item) }}
          </td>
        </tr>
        <!-- 最高连败 -->
        <tr>
          <td
            v-for="item in latelyData.detailData"
            style="font-size: 14px; text-align: center"
          >
            最高连败：<br />{{ getHighestDefeatStreak(item) }}
          </td>
        </tr>
        <!-- 最高单局胜利 -->
        <tr>
          <td
            v-for="item in latelyData.detailData"
            style="font-size: 14px; text-align: center"
          >
            最高单局胜利：<br />{{
              getHighestSingleVictory(item.mahjongRecord)
            }}
          </td>
        </tr>
        <!-- 最高单局失败 -->
        <tr>
          <td
            v-for="item in latelyData.detailData"
            style="font-size: 14px; text-align: center"
          >
            最高单局失败：<br />{{ getHighestSingleDefeat(item.mahjongRecord) }}
          </td>
        </tr>
      </tbody>
    </table>
  </el-dialog>

  <el-dialog
    center
    v-model="sumData.showDetail"
    title="历史战绩"
    style="width: 90%; max-width: 450px"
  >
    <div style="display: flex; justify-content: space-between">
      <!-- 添加一个复制按钮 -->
      <el-button
        text
        type="success"
        size="default"
        @click="copyData(mahjongRecord2String(sumData.detailData, false))"
        style="margin: 0 auto"
        >复制不含战绩数据</el-button
      >
      <el-button
        text
        type="success"
        size="default"
        @click="copyData(mahjongRecord2String(sumData.detailData, true))"
        style="margin: 0 auto"
        >复制完整数据</el-button
      >
    </div>

    <table>
      <tbody>
        <th v-for="item in sumData.detailData">{{ item.name }} <br /></th>
        <tr style="margin-top: 20px">
          <td
            v-for="item in sumData.detailData"
            style="font-size: 14px; text-align: center"
          >
            胜率：{{ getWinningProbability(item) }}<br />{{
              getWinningText(item)
            }}
          </td>
        </tr>
        <div class="table">
          <tr>
            <td v-for="item in sumData.detailData" style="border: none">
              <!-- 循环输出item中的每一项 -->
              <div
                type="primary"
                size="default"
                v-for="(m, index) in item.mahjongRecord"
              >
                <div class="card1">
                  <code :style="totalColor(m)">
                    {{ m > 0 ? "+" : "" }}{{ m }}
                  </code>
                </div>
              </div>
            </td>
          </tr>
        </div>

        <tr class="total">
          <td
            v-for="item in sumData.detailData"
            :style="
              totalColor(item.moneyOfTotal) +
              ';font-size: 30px;font-weight: bold'
            "
          >
            <!-- 循环输出item中的每一项 -->
            {{ item.moneyOfTotal }}
          </td>
        </tr>

        <!-- 最高连胜 -->
        <tr>
          <td
            v-for="item in sumData.detailData"
            style="font-size: 14px; text-align: center"
          >
            最高连胜：<br />{{ getHighestVictoryStreak(item) }}
          </td>
        </tr>
        <!-- 最高连败 -->
        <tr>
          <td
            v-for="item in sumData.detailData"
            style="font-size: 14px; text-align: center"
          >
            最高连败：<br />{{ getHighestDefeatStreak(item) }}
          </td>
        </tr>
        <!-- 最高单局胜利 -->
        <tr>
          <td
            v-for="item in sumData.detailData"
            style="font-size: 14px; text-align: center"
          >
            最高单局胜利：<br />{{
              getHighestSingleVictory(item.mahjongRecord)
            }}
          </td>
        </tr>
        <!-- 最高单局失败 -->
        <tr>
          <td
            v-for="item in sumData.detailData"
            style="font-size: 14px; text-align: center"
          >
            最高单局失败：<br />{{ getHighestSingleDefeat(item.mahjongRecord) }}
          </td>
        </tr>
      </tbody>
    </table>
  </el-dialog>
</template>

<style scoped>
.main {
  max-width: 500px;
  margin: 0 auto;
}
.operation {
  position: fixed;
  bottom: 20px;
  width: 100%;
  max-width: 500px;
  z-index: 100;
}
@media screen and (max-width: 500px) {
  .operation {
    left: 0;
  }
}
.buttons {
  display: flex;
  justify-content: space-around;
}
.version {
  /* 灰色字体，居中底部 */
  color: #999;
  text-align: center;
  /* position: fixed; */
  bottom: 0;
  width: 100%;
  /* 字体小 */
  font-size: 14px;
  margin: 10px;
  margin: 0;
  padding: 0;
}
.info {
  margin: 10px;
}
.el-button + .el-button {
  margin-left: 0;
}
.lately {
  margin-top: 20px;
}
.latelyRecord {
  background-color: #999;
  padding: 10px;
  border: 2px solid blue;
}
table {
  /* 加粗 */
  font-weight: bold;
  margin: 0 auto;
  width: 100%;
  font-size: 20px;
  border-collapse: collapse;
}
table,
th,
td {
  border: 1px solid;
  text-align: center;
}
.table {
  max-height: 50vh;
  overflow: auto;
  text-align: center;
  margin: 0 auto;
  display: flex;
}
th {
  position: sticky;
  top: 0; /* 第一列最上 */
  background-color: rgb(181, 178, 178);
}

.table tr {
  margin: 0 auto;
}
.total td {
  border: none;
  margin: 0 auto;
}

.card2 {
  /* 背景色 */
  background-color: #999;
  /* 边框 */
  border: 2px solid blue;
  /* 圆角 */
  border-radius: 10px;
  /* 内边距 */
  padding: 5px;
  /* 外边距 */
  margin: 5px;
  /* 字体大小 */
  font-size: 20px;
  /* 字体居中 */
  text-align: center;
  /* 字体加粗 */
  font-weight: bold;
  display: flex;
}
.el-dialog + .el-dialog--center {
  margin-top: 10px;
}
.roomNumber {
  /* 代码块样式 */
  background-color: #999;
  /* 圆角 */
  border-radius: 7px;
  /* 内边距 */
  padding: 5px;
  /* 外边距 */
  margin: 10px;
  /* 字体居中 */
  text-align: center;
  /* 字体加粗 */
  font-weight: bold;
}
</style>
